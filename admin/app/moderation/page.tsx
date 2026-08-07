import { supabaseAdmin } from "@/lib/supabase-admin";
import ModerationTable from "./moderation-table";
import type { ModerationPost } from "@/lib/types";

export const dynamic = "force-dynamic";

const P1_REASONS = new Set(["threats", "pii", "sexual"]);

async function getModerationPosts(): Promise<{
  p1Posts: ModerationPost[];
  p2Posts: ModerationPost[];
}> {
  const { data: posts, error } = await supabaseAdmin
    .from("posts")
    .select(
      "*, author:users!posts_user_id_fkey(id, username, user_number), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name)"
    )
    .in("status", ["under_review", "removed"])
    .order("created_at", { ascending: true });

  if (error || !posts) return { p1Posts: [], p2Posts: [] };

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

  // Fetch strike counts per author
  const authorIds = [
    ...new Set(posts.map((p) => p.author?.id).filter(Boolean)),
  ];
  const { data: strikes } = await supabaseAdmin
    .from("strikes")
    .select("user_id")
    .in("user_id", authorIds.length > 0 ? authorIds : ["__none__"]);

  const strikeCountByUser = new Map<string, number>();
  for (const s of strikes ?? []) {
    strikeCountByUser.set(
      s.user_id,
      (strikeCountByUser.get(s.user_id) ?? 0) + 1
    );
  }

  const enrichedPosts = posts.map((post) => ({
    ...post,
    reports: reportsByPost.get(post.id) ?? [],
    authorStrikeCount: post.author?.id
      ? strikeCountByUser.get(post.author.id) ?? 0
      : 0,
  })) as (ModerationPost & { authorStrikeCount: number })[];

  const p1Posts = enrichedPosts.filter((post) =>
    post.reports.some((r) => P1_REASONS.has(r.reason))
  );
  const p2Posts = enrichedPosts.filter(
    (post) => !post.reports.some((r) => P1_REASONS.has(r.reason))
  );

  return { p1Posts, p2Posts };
}

export default async function ModerationPage() {
  const { p1Posts, p2Posts } = await getModerationPosts();
  const totalCount = p1Posts.length + p2Posts.length;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">Content Moderation</h2>
        <span className="text-sm text-gray-500">
          {totalCount} post{totalCount !== 1 ? "s" : ""} requiring attention
        </span>
      </div>

      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
          <span className="inline-block w-2 h-2 rounded-full bg-red-500" />
          Priority 1 — Same-day
          <span className="text-sm font-normal text-gray-500">
            (threats, PII, sexual)
          </span>
        </h3>
        {p1Posts.length > 0 ? (
          <ModerationTable posts={p1Posts} showAge />
        ) : (
          <div className="bg-white rounded-lg border border-gray-200 p-6 text-center text-gray-500 text-sm">
            No P1 items.
          </div>
        )}
      </div>

      <div>
        <h3 className="text-lg font-semibold mb-3 flex items-center gap-2">
          <span className="inline-block w-2 h-2 rounded-full bg-yellow-500" />
          Priority 2 — Weekly batch
          <span className="text-sm font-normal text-gray-500">
            (hate, spam, other)
          </span>
        </h3>
        {p2Posts.length > 0 ? (
          <ModerationTable posts={p2Posts} showAge={false} />
        ) : (
          <div className="bg-white rounded-lg border border-gray-200 p-6 text-center text-gray-500 text-sm">
            No P2 items.
          </div>
        )}
      </div>
    </div>
  );
}
