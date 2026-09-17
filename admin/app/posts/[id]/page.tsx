import { supabaseAdmin } from "@/lib/supabase-admin";
import { notFound } from "next/navigation";
import Link from "next/link";
import RepliesList from "./replies-list";

export const dynamic = "force-dynamic";

interface Props {
  params: Promise<{ id: string }>;
}

export default async function PostDetailPage({ params }: Props) {
  const { id } = await params;

  const { data: post } = await supabaseAdmin
    .from("posts")
    .select(
      "id, text, score, reply_count, report_count, status, moderation_reason, created_at, user_id, author:users!posts_user_id_fkey(username, user_number, home:neighborhoods(name, short_code)), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name, short_code)"
    )
    .eq("id", id)
    .single();

  if (!post) {
    notFound();
  }

  const author = Array.isArray(post.author)
    ? post.author[0] ?? null
    : post.author;
  const neighborhood = Array.isArray(post.neighborhood)
    ? post.neighborhood[0] ?? null
    : post.neighborhood;

  const { data: replies } = await supabaseAdmin
    .from("replies")
    .select(
      "id, text, score, created_at, parent_reply_id, author:users!replies_user_id_fkey(username, user_number)"
    )
    .eq("post_id", id)
    .order("created_at", { ascending: true });

  const mappedReplies = (replies ?? []).map((r: any) => ({
    ...r,
    author: Array.isArray(r.author) ? r.author[0] ?? null : r.author,
  }));

  // Fetch reports if any
  const { data: reports } = await supabaseAdmin
    .from("reports")
    .select("id, reason, created_at, reporter:users!reports_reporter_id_fkey(username)")
    .eq("post_id", id)
    .order("created_at", { ascending: false });

  const mappedReports = (reports ?? []).map((r: any) => ({
    ...r,
    reporter: Array.isArray(r.reporter) ? r.reporter[0] ?? null : r.reporter,
  }));

  return (
    <div>
      <Link
        href="/posts"
        className="text-sm text-blue-600 hover:underline mb-4 inline-block"
      >
        &larr; Back to Posts
      </Link>

      <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <div className="flex items-start justify-between mb-4">
          <h2 className="text-xl font-bold">Post Detail</h2>
          <StatusBadge status={post.status} />
        </div>

        <div className="bg-gray-50 rounded-lg border border-gray-200 p-4 mb-6">
          <p className="text-gray-800 whitespace-pre-wrap">{post.text}</p>
        </div>

        <dl className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
          <div>
            <dt className="text-gray-500 font-medium">Author</dt>
            <dd className="mt-1">
              {author
                ? `${author.username}#${author.user_number}`
                : "\u2014"}
            </dd>
          </div>
          <div>
            <dt className="text-gray-500 font-medium">Author Home</dt>
            <dd className="mt-1">
              {(author as any)?.home?.name ?? "\u2014"}
            </dd>
          </div>
          <div>
            <dt className="text-gray-500 font-medium">Neighborhood</dt>
            <dd className="mt-1">
              {neighborhood
                ? `${neighborhood.name} (${neighborhood.short_code})`
                : "\u2014"}
            </dd>
          </div>
          <div>
            <dt className="text-gray-500 font-medium">Score</dt>
            <dd className="mt-1">{post.score}</dd>
          </div>
          <div>
            <dt className="text-gray-500 font-medium">Replies</dt>
            <dd className="mt-1">{post.reply_count}</dd>
          </div>
          <div>
            <dt className="text-gray-500 font-medium">Reports</dt>
            <dd className="mt-1">{post.report_count ?? 0}</dd>
          </div>
          <div>
            <dt className="text-gray-500 font-medium">Created</dt>
            <dd className="mt-1">
              {new Date(post.created_at).toLocaleString()}
            </dd>
          </div>
          {post.moderation_reason && (
            <div>
              <dt className="text-gray-500 font-medium">Moderation Reason</dt>
              <dd className="mt-1 text-red-600">{post.moderation_reason}</dd>
            </div>
          )}
        </dl>

        <div className="mt-2 text-xs text-gray-400 font-mono">{post.id}</div>
      </div>

      {/* Reports section */}
      {mappedReports.length > 0 && (
        <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
          <h3 className="text-lg font-semibold mb-4">
            Reports ({mappedReports.length})
          </h3>
          <div className="space-y-2">
            {mappedReports.map((report: any) => (
              <div
                key={report.id}
                className="flex items-center justify-between bg-red-50 rounded border border-red-200 px-4 py-2 text-sm"
              >
                <span className="font-medium text-red-700">
                  {report.reason}
                </span>
                <span className="text-gray-500">
                  by {report.reporter?.username ?? "unknown"} &middot;{" "}
                  {new Date(report.created_at).toLocaleDateString()}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Replies section */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold mb-4">
          Replies ({mappedReplies.length})
        </h3>
        {mappedReplies.length === 0 ? (
          <p className="text-sm text-gray-500">No replies yet.</p>
        ) : (
          <RepliesList replies={mappedReplies} postId={post.id} />
        )}
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
