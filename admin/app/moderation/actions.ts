"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase-admin";

export async function updatePostStatus(postId: string, newStatus: "live" | "removed") {
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

  if (newStatus === "live") {
    const { error: deleteError } = await supabaseAdmin
      .from("reports")
      .delete()
      .eq("post_id", postId);

    if (deleteError) {
      return { error: deleteError.message };
    }
  }

  revalidatePath("/moderation");
  revalidatePath("/");
  return { success: true };
}
