import { supabaseAdmin } from "@/lib/supabase-admin";
import StatCard from "@/components/stat-card";
import TrendCard from "@/components/trend-card";
import NeedsAction from "@/components/needs-action";
import RecentPostsTable from "@/components/recent-posts-table";

export const dynamic = "force-dynamic";

const P1_REASONS = new Set(["threats", "pii", "sexual"]);

async function getNeedsActionData() {
  // Fetch reported posts with reports
  const { data: reportedPosts } = await supabaseAdmin
    .from("posts")
    .select(
      "id, text, status, created_at, report_count, author:users!posts_user_id_fkey(username), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name)"
    )
    .in("status", ["under_review", "removed"])
    .order("created_at", { ascending: true });

  const postIds = (reportedPosts ?? []).map((p) => p.id);
  const { data: reports } = await supabaseAdmin
    .from("reports")
    .select("post_id, reason")
    .in("post_id", postIds.length > 0 ? postIds : ["__none__"]);

  const reportsByPost = new Map<string, { reason: string }[]>();
  for (const report of reports ?? []) {
    const existing = reportsByPost.get(report.post_id) ?? [];
    existing.push({ reason: report.reason });
    reportsByPost.set(report.post_id, existing);
  }

  const enrichedPosts = (reportedPosts ?? []).map((post) => ({
    ...post,
    reports: reportsByPost.get(post.id) ?? [],
  }));

  const p1Posts = enrichedPosts.filter((post) =>
    post.reports.some((r) => P1_REASONS.has(r.reason))
  );
  const p2Posts = enrichedPosts.filter(
    (post) => !post.reports.some((r) => P1_REASONS.has(r.reason))
  );

  // Pending appeals
  const { data: appeals } = await supabaseAdmin
    .from("appeals")
    .select(
      "id, appeal_text, created_at, user:users!appeals_user_id_fkey(username, user_number)"
    )
    .eq("status", "pending")
    .order("created_at", { ascending: true });

  return {
    p1Posts: p1Posts.slice(0, 10),
    p1Total: p1Posts.length,
    p2Count: p2Posts.length,
    pendingAppeals: (appeals ?? []).slice(0, 5),
    appealsTotal: (appeals ?? []).length,
  };
}

async function getTrendMetrics() {
  const now = new Date();
  const today = new Date(now);
  today.setHours(0, 0, 0, 0);

  // Current period: last 7 days. Prior period: 7 days before that.
  const currentStart = new Date(now);
  currentStart.setDate(currentStart.getDate() - 7);
  const priorStart = new Date(currentStart);
  priorStart.setDate(priorStart.getDate() - 7);

  // Organic posts (last 14 days, joined with non-seed users)
  const { data: organicPostsRaw } = await supabaseAdmin
    .from("posts")
    .select("created_at, user_id")
    .gte("created_at", priorStart.toISOString());

  const { data: seedUsers } = await supabaseAdmin
    .from("users")
    .select("id")
    .eq("is_seed", true);

  const seedIds = new Set((seedUsers ?? []).map((u) => u.id));
  const organicPosts = (organicPostsRaw ?? []).filter(
    (p) => !seedIds.has(p.user_id)
  );

  const currentOrganic = organicPosts.filter(
    (p) => new Date(p.created_at) >= currentStart
  ).length;
  const priorOrganic = organicPosts.filter(
    (p) =>
      new Date(p.created_at) >= priorStart &&
      new Date(p.created_at) < currentStart
  ).length;

  // Today's organic posts
  const todayOrganic = organicPosts.filter(
    (p) => new Date(p.created_at) >= today
  ).length;

  // Reply rate: replies / posts trailing 7 days
  const { count: currentReplies } = await supabaseAdmin
    .from("replies")
    .select("*", { count: "exact", head: true })
    .gte("created_at", currentStart.toISOString());

  const { count: currentPosts } = await supabaseAdmin
    .from("posts")
    .select("*", { count: "exact", head: true })
    .gte("created_at", currentStart.toISOString());

  const { count: priorReplies } = await supabaseAdmin
    .from("replies")
    .select("*", { count: "exact", head: true })
    .gte("created_at", priorStart.toISOString())
    .lt("created_at", currentStart.toISOString());

  const { count: priorPosts } = await supabaseAdmin
    .from("posts")
    .select("*", { count: "exact", head: true })
    .gte("created_at", priorStart.toISOString())
    .lt("created_at", currentStart.toISOString());

  const currentReplyRate =
    (currentPosts ?? 0) > 0
      ? ((currentReplies ?? 0) / (currentPosts ?? 1)).toFixed(1)
      : "0";
  const priorReplyRate =
    (priorPosts ?? 0) > 0
      ? (priorReplies ?? 0) / (priorPosts ?? 1)
      : 0;

  // New organic signups
  const { data: signupsRaw } = await supabaseAdmin
    .from("users")
    .select("created_at, is_seed")
    .eq("is_seed", false)
    .gte("created_at", priorStart.toISOString());

  const currentSignups = (signupsRaw ?? []).filter(
    (u) => new Date(u.created_at) >= currentStart
  ).length;
  const priorSignups = (signupsRaw ?? []).filter(
    (u) =>
      new Date(u.created_at) >= priorStart &&
      new Date(u.created_at) < currentStart
  ).length;

  // Reports per 100 posts
  const { count: totalReportsRecent } = await supabaseAdmin
    .from("reports")
    .select("*", { count: "exact", head: true })
    .gte("created_at", currentStart.toISOString());

  const { count: totalReportsPrior } = await supabaseAdmin
    .from("reports")
    .select("*", { count: "exact", head: true })
    .gte("created_at", priorStart.toISOString())
    .lt("created_at", currentStart.toISOString());

  const currentReportRate =
    (currentPosts ?? 0) > 0
      ? (((totalReportsRecent ?? 0) / (currentPosts ?? 1)) * 100).toFixed(1)
      : "0";
  const priorReportRate =
    (priorPosts ?? 0) > 0
      ? ((totalReportsPrior ?? 0) / (priorPosts ?? 1)) * 100
      : 0;

  return {
    organicPostsToday: todayOrganic,
    currentOrganic,
    priorOrganic,
    replyRate: currentReplyRate,
    priorReplyRate,
    currentReplyRateNum: parseFloat(currentReplyRate),
    currentSignups,
    priorSignups,
    reportRate: currentReportRate,
    priorReportRate,
    currentReportRateNum: parseFloat(currentReportRate),
  };
}

async function getCumulativeStats() {
  const [
    { count: totalUsers },
    { count: totalPosts },
    { count: totalReplies },
    { count: totalFeedback },
  ] = await Promise.all([
    supabaseAdmin.from("users").select("*", { count: "exact", head: true }),
    supabaseAdmin.from("posts").select("*", { count: "exact", head: true }),
    supabaseAdmin.from("replies").select("*", { count: "exact", head: true }),
    supabaseAdmin.from("feedback").select("*", { count: "exact", head: true }),
  ]);

  const { data: neighborhoodData } = await supabaseAdmin
    .from("posts")
    .select("neighborhood_id")
    .eq("status", "live");

  const activeNeighborhoods = new Set(
    neighborhoodData?.map((p) => p.neighborhood_id)
  ).size;

  return {
    totalUsers: totalUsers ?? 0,
    totalPosts: totalPosts ?? 0,
    totalReplies: totalReplies ?? 0,
    totalFeedback: totalFeedback ?? 0,
    activeNeighborhoods,
  };
}

async function getRecentPosts() {
  const { data } = await supabaseAdmin
    .from("posts")
    .select(
      "id, text, score, reply_count, status, created_at, author:users!posts_user_id_fkey(username, user_number), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name)"
    )
    .order("created_at", { ascending: false })
    .limit(15);

  return data ?? [];
}

export default async function DashboardPage() {
  const [actionData, trends, cumulative, recentPosts] = await Promise.all([
    getNeedsActionData(),
    getTrendMetrics(),
    getCumulativeStats(),
    getRecentPosts(),
  ]);

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Dashboard</h2>

      {/* Section 1: Needs Action */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-3">Needs Action</h3>
        <NeedsAction
          p1Posts={actionData.p1Posts}
          p1Total={actionData.p1Total}
          p2Count={actionData.p2Count}
          pendingAppeals={actionData.pendingAppeals}
          appealsTotal={actionData.appealsTotal}
        />
      </div>

      {/* Section 2: Trend Metrics */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-3">Metrics (7-day)</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <TrendCard
            label="Organic Posts / Day"
            value={trends.organicPostsToday}
            currentValue={trends.currentOrganic}
            previousValue={trends.priorOrganic}
            suffix="today"
          />
          <TrendCard
            label="Reply Rate"
            value={trends.replyRate}
            currentValue={trends.currentReplyRateNum}
            previousValue={trends.priorReplyRate}
            suffix="replies/post"
          />
          <TrendCard
            label="New Signups (7d)"
            value={trends.currentSignups}
            currentValue={trends.currentSignups}
            previousValue={trends.priorSignups}
          />
          <TrendCard
            label="Reports / 100 Posts"
            value={trends.reportRate}
            currentValue={trends.currentReportRateNum}
            previousValue={trends.priorReportRate}
          />
        </div>
      </div>

      {/* Section 3: Recent Posts */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-3">Recent Posts</h3>
        <RecentPostsTable posts={recentPosts} />
      </div>

      {/* Section 4: Cumulative Stats Strip */}
      <div className="flex flex-wrap gap-4 border-t border-gray-200 pt-4">
        <StatCard label="Total Users" value={cumulative.totalUsers} />
        <StatCard label="Total Posts" value={cumulative.totalPosts} />
        <StatCard label="Total Replies" value={cumulative.totalReplies} />
        <StatCard
          label="Total Feedback"
          value={cumulative.totalFeedback}
          accent="green"
        />
        <StatCard
          label="Active Neighborhoods"
          value={cumulative.activeNeighborhoods}
          accent="green"
        />
      </div>
    </div>
  );
}
