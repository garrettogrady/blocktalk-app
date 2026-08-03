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

  if (newStatus === "accepted") {
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
  }

  revalidatePath("/appeals");
  revalidatePath("/moderation");
  revalidatePath("/");
  return { success: true };
}
