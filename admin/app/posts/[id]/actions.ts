"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase-admin";

export async function deleteReply(replyId: string, postId: string) {
  const { error } = await supabaseAdmin
    .from("replies")
    .delete()
    .eq("id", replyId);

  if (error) {
    return { error: error.message };
  }

  // Recount replies for accuracy
  const { count } = await supabaseAdmin
    .from("replies")
    .select("*", { count: "exact", head: true })
    .eq("post_id", postId);

  await supabaseAdmin
    .from("posts")
    .update({ reply_count: count ?? 0 })
    .eq("id", postId);

  revalidatePath(`/posts/${postId}`);
  revalidatePath("/posts");
  revalidatePath("/");
  return { success: true };
}
