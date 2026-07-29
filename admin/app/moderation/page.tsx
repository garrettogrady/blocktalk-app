import { supabaseAdmin } from "@/lib/supabase-admin";
import ModerationTable from "./moderation-table";
import type { ModerationPost } from "@/lib/types";

export const dynamic = "force-dynamic";

async function getModerationPosts(): Promise<ModerationPost[]> {
  const { data: posts, error } = await supabaseAdmin
    .from("posts")
    .select(
      "*, author:users!posts_user_id_fkey(username, user_number), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name)"
    )
    .in("status", ["under_review", "removed"])
    .order("created_at", { ascending: false });

  if (error || !posts) return [];

  const postIds = posts.map((p) => p.id);

  const { data: reports } = await supabaseAdmin
    .from("reports")
    .select("*, reporter:users!reports_reporter_id_fkey(username)")
    .in("post_id", postIds.length > 0 ? postIds : ["__none__"]);

  const reportsByPost = new Map<string, typeof reports>();
  for (const report of reports ?? []) {
    const existing = reportsByPost.get(report.post_id) ?? [];
    existing.push(report);
    reportsByPost.set(report.post_id, existing);
  }

  return posts.map((post) => ({
    ...post,
    reports: reportsByPost.get(post.id) ?? [],
  })) as ModerationPost[];
}

export default async function ModerationPage() {
  const posts = await getModerationPosts();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">Content Moderation</h2>
        <span className="text-sm text-gray-500">
          {posts.length} post{posts.length !== 1 ? "s" : ""} requiring attention
        </span>
      </div>
      <ModerationTable posts={posts} />
    </div>
  );
}
