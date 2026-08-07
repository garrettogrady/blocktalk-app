"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase-admin";
import type { AppealStatus } from "@/lib/types";

export async function updateAppealStatus(
  appealId: string,
  newStatus: "accepted" | "rejected"
) {
  const { data: appeal, error: fetchError } = await supabaseAdmin
    .from("appeals")
    .select("post_id")
    .eq("id", appealId)
    .single();

  if (fetchError || !appeal) {
    return { error: fetchError?.message ?? "Appeal not found" };
  }

  const { error: updateError } = await supabaseAdmin
    .from("appeals")
    .update({ status: newStatus as AppealStatus })
    .eq("id", appealId);

  if (updateError) {
    return { error: updateError.message };
  }

  // Get post author for audit log
  const { data: post } = await supabaseAdmin
    .from("posts")
    .select("user_id")
    .eq("id", appeal.post_id)
    .single();

  if (newStatus === "accepted") {
    // Overturn: restore post, log action, remove strike
    const { error: postError } = await supabaseAdmin
      .from("posts")
      .update({ status: "live", report_count: 0 })
      .eq("id", appeal.post_id);

    if (postError) {
      return { error: postError.message };
    }

    await supabaseAdmin
      .from("reports")
      .delete()
      .eq("post_id", appeal.post_id);

    // Log overturn action
    await supabaseAdmin.from("moderation_actions").insert({
      post_id: appeal.post_id,
      user_id: post?.user_id ?? null,
      action: "overturn",
    });

    // Remove strike for this post if one exists
    await supabaseAdmin
      .from("strikes")
      .delete()
      .eq("post_id", appeal.post_id);
  } else {
    // Reject (uphold removal): log action
    await supabaseAdmin.from("moderation_actions").insert({
      post_id: appeal.post_id,
      user_id: post?.user_id ?? null,
      action: "uphold",
    });
  }

  revalidatePath("/appeals");
  revalidatePath("/moderation");
  revalidatePath("/");
  return { success: true };
}
