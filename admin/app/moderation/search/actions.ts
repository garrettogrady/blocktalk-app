"use server";

import { supabaseAdmin } from "@/lib/supabase-admin";

export async function searchPosts(
  query: string,
  neighborhoodId: string,
  status: string
) {
  let q = supabaseAdmin
    .from("posts")
    .select(
      "id, text, score, reply_count, status, created_at, author:users!posts_user_id_fkey(username, user_number), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name)"
    )
    .order("created_at", { ascending: false })
    .limit(50);

  if (query.trim()) {
    q = q.ilike("text", `%${query.trim()}%`);
  }

  if (neighborhoodId) {
    q = q.eq("neighborhood_id", neighborhoodId);
  }

  if (status) {
    q = q.eq("status", status);
  }

  const { data } = await q;
  return (data ?? []).map((row: any) => ({
    ...row,
    author: Array.isArray(row.author) ? row.author[0] ?? null : row.author,
    neighborhood: Array.isArray(row.neighborhood) ? row.neighborhood[0] ?? null : row.neighborhood,
  }));
}
