import { supabaseAdmin } from "@/lib/supabase-admin";
import StatCard from "@/components/stat-card";

export const dynamic = "force-dynamic";

async function getMetrics() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const [
    { count: totalUsers },
    { count: totalPosts },
    { count: postsToday },
    { count: postsUnderReview },
    { count: postsRemoved },
    { count: totalReports },
    { count: totalReplies },
    { count: pendingAppeals },
    { count: totalFeedback },
  ] = await Promise.all([
    supabaseAdmin.from("users").select("*", { count: "exact", head: true }),
    supabaseAdmin.from("posts").select("*", { count: "exact", head: true }),
    supabaseAdmin
      .from("posts")
      .select("*", { count: "exact", head: true })
      .gte("created_at", today.toISOString()),
    supabaseAdmin
      .from("posts")
      .select("*", { count: "exact", head: true })
      .eq("status", "under_review"),
    supabaseAdmin
      .from("posts")
      .select("*", { count: "exact", head: true })
      .eq("status", "removed"),
    supabaseAdmin.from("reports").select("*", { count: "exact", head: true }),
    supabaseAdmin.from("replies").select("*", { count: "exact", head: true }),
    supabaseAdmin
      .from("appeals")
      .select("*", { count: "exact", head: true })
      .eq("status", "pending"),
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
    postsToday: postsToday ?? 0,
    postsUnderReview: postsUnderReview ?? 0,
    postsRemoved: postsRemoved ?? 0,
    totalReports: totalReports ?? 0,
    totalReplies: totalReplies ?? 0,
    pendingAppeals: pendingAppeals ?? 0,
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
    .limit(10);

  return data ?? [];
}

export default async function DashboardPage() {
  const metrics = await getMetrics();
  const recentPosts = await getRecentPosts();

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Dashboard</h2>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <StatCard label="Total Users" value={metrics.totalUsers} />
        <StatCard label="Total Posts" value={metrics.totalPosts} />
        <StatCard label="Posts Today" value={metrics.postsToday} accent="green" />
        <StatCard label="Total Replies" value={metrics.totalReplies} />
        <StatCard
          label="Under Review"
          value={metrics.postsUnderReview}
          accent="yellow"
        />
        <StatCard
          label="Removed"
          value={metrics.postsRemoved}
          accent="red"
        />
        <StatCard label="Total Reports" value={metrics.totalReports} accent="red" />
        <StatCard
          label="Pending Appeals"
          value={metrics.pendingAppeals}
          accent="yellow"
        />
        <StatCard
          label="Total Feedback"
          value={metrics.totalFeedback}
          accent="green"
        />
        <StatCard
          label="Active Neighborhoods"
          value={metrics.activeNeighborhoods}
          accent="green"
        />
      </div>

      <h3 className="text-lg font-semibold mb-3">Recent Posts</h3>
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Author
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Text
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Neighborhood
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Score
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Status
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Created
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {recentPosts.map((post: any) => (
              <tr key={post.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">
                  {post.author?.username ?? "—"}
                </td>
                <td className="px-4 py-3 max-w-md truncate text-gray-600">
                  {post.text}
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {post.neighborhood?.name ?? "—"}
                </td>
                <td className="px-4 py-3">{post.score}</td>
                <td className="px-4 py-3">
                  <StatusBadge status={post.status} />
                </td>
                <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                  {new Date(post.created_at).toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    live: "bg-green-100 text-green-700",
    under_review: "bg-yellow-100 text-yellow-700",
    removed: "bg-red-100 text-red-700",
  };
  return (
    <span
      className={`inline-block px-2 py-0.5 rounded-full text-xs font-medium ${
        colors[status] ?? "bg-gray-100 text-gray-600"
      }`}
    >
      {status}
    </span>
  );
}
