"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase-admin";

export async function updatePostStatus(
  postId: string,
  newStatus: "live" | "removed",
  reason?: string,
  adminNote?: string
) {
  // Fetch the post to get author info
  const { data: post } = await supabaseAdmin
    .from("posts")
    .select("user_id")
    .eq("id", postId)
    .single();

  const { error: updateError } = await supabaseAdmin
    .from("posts")
    .update({
      status: newStatus,
      ...(newStatus === "live" ? { report_count: 0 } : {}),
    })
    .eq("id", postId);

  if (updateError) {
    return { error: updateError.message };
  }

  // Log moderation action
  const action = newStatus === "removed" ? "remove" : "restore";
  const { data: modAction } = await supabaseAdmin
    .from("moderation_actions")
    .insert({
      post_id: postId,
      user_id: post?.user_id ?? null,
      action,
      reason: action === "remove" ? (reason ?? null) : null,
      admin_note: adminNote ?? null,
    })
    .select("id")
    .single();

  // Create strike on remove (not on auto-hide)
  if (action === "remove" && post?.user_id && modAction) {
    await supabaseAdmin.from("strikes").insert({
      user_id: post.user_id,
      post_id: postId,
      moderation_action_id: modAction.id,
    });
  }

  if (newStatus === "live") {
    await supabaseAdmin.from("reports").delete().eq("post_id", postId);
  }

  revalidatePath("/moderation");
  revalidatePath("/");
  return { success: true };
}

export async function directRemovePost(
  postId: string,
  reason: string,
  adminNote?: string
) {
  return updatePostStatus(postId, "removed", reason, adminNote);
}
