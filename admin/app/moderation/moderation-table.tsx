"use client";

import { useState } from "react";
import { ChevronDown, ChevronRight, CheckCircle, XCircle } from "lucide-react";
import { updatePostStatus } from "./actions";
import type { ModerationPost } from "@/lib/types";

export default function ModerationTable({ posts }: { posts: ModerationPost[] }) {
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [loading, setLoading] = useState<string | null>(null);

  async function handleAction(postId: string, newStatus: "live" | "removed") {
    setLoading(postId);
    const result = await updatePostStatus(postId, newStatus);
    if (result.error) {
      alert(`Error: ${result.error}`);
    }
    setLoading(null);
  }

  if (posts.length === 0) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-8 text-center text-gray-500">
        No posts require moderation.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {posts.map((post) => {
        const expanded = expandedId === post.id;
        const isLoading = loading === post.id;

        return (
          <div
            key={post.id}
            className="bg-white rounded-lg border border-gray-200 overflow-hidden"
          >
            <div className="px-4 py-3 flex items-start gap-3">
              <button
                onClick={() => setExpandedId(expanded ? null : post.id)}
                className="mt-1 text-gray-400 hover:text-gray-600"
              >
                {expanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
              </button>

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium text-sm">
                    {post.author?.username ?? "Unknown"}
                  </span>
                  <span className="text-xs text-gray-400">
                    in {post.neighborhood?.name ?? "—"}
                  </span>
                  <StatusBadge status={post.status} />
                  <span className="text-xs text-gray-400">
                    {post.report_count} report{post.report_count !== 1 ? "s" : ""}
                  </span>
                </div>
                <p className="text-sm text-gray-700 line-clamp-2">{post.text}</p>
              </div>

              <div className="flex gap-2 shrink-0">
                <button
                  onClick={() => handleAction(post.id, "live")}
                  disabled={isLoading}
                  className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md bg-green-50 text-green-700 hover:bg-green-100 disabled:opacity-50 transition-colors"
                >
                  <CheckCircle size={14} />
                  Approve
                </button>
                <button
                  onClick={() => handleAction(post.id, "removed")}
                  disabled={isLoading}
                  className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md bg-red-50 text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors"
                >
                  <XCircle size={14} />
                  Remove
                </button>
              </div>
            </div>

            {expanded && post.reports.length > 0 && (
              <div className="border-t border-gray-100 bg-gray-50 px-4 py-3">
                <p className="text-xs font-medium text-gray-500 mb-2">Reports</p>
                <div className="space-y-2">
                  {post.reports.map((report) => (
                    <div
                      key={report.id}
                      className="bg-white rounded border border-gray-200 px-3 py-2 text-sm"
                    >
                      <div className="flex items-center gap-2 mb-1">
                        <span className="font-medium text-xs">
                          {report.reporter?.username ?? "Unknown"}
                        </span>
                        <span className="px-1.5 py-0.5 bg-gray-100 rounded text-xs text-gray-600">
                          {report.reason}
                        </span>
                        <span className="text-xs text-gray-400">
                          {new Date(report.created_at).toLocaleDateString()}
                        </span>
                      </div>
                      {report.free_text && (
                        <p className="text-gray-600 text-xs">{report.free_text}</p>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        );
      })}
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
