"use client";

import { useState } from "react";
import {
  ChevronDown,
  ChevronRight,
  CheckCircle,
  XCircle,
  Clock,
  AlertTriangle,
} from "lucide-react";
import { updatePostStatus } from "./actions";
import type { ModerationPost } from "@/lib/types";

const VIOLATION_REASONS = [
  "threats",
  "pii",
  "sexual",
  "hate",
  "spam",
  "other",
];

function formatAge(createdAt: string): string {
  const diffMs = Date.now() - new Date(createdAt).getTime();
  const hours = Math.floor(diffMs / (1000 * 60 * 60));
  if (hours < 1) {
    const mins = Math.floor(diffMs / (1000 * 60));
    return `${mins}m`;
  }
  if (hours < 48) return `${hours}h`;
  const days = Math.floor(hours / 24);
  return `${days}d`;
}

function isOverdue(createdAt: string, thresholdHours: number): boolean {
  const diffMs = Date.now() - new Date(createdAt).getTime();
  return diffMs > thresholdHours * 60 * 60 * 1000;
}

interface ModerationTableProps {
  posts: (ModerationPost & { authorStrikeCount?: number })[];
  showAge?: boolean;
}

export default function ModerationTable({
  posts,
  showAge = true,
}: ModerationTableProps) {
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [loading, setLoading] = useState<string | null>(null);
  const [removingId, setRemovingId] = useState<string | null>(null);
  const [selectedReason, setSelectedReason] = useState<string>("");
  const [adminNote, setAdminNote] = useState<string>("");

  async function handleRestore(postId: string) {
    setLoading(postId);
    const result = await updatePostStatus(postId, "live");
    if (result.error) {
      alert(`Error: ${result.error}`);
    }
    setLoading(null);
  }

  async function handleRemoveConfirm(postId: string) {
    if (!selectedReason) {
      alert("Please select a violation reason.");
      return;
    }
    setLoading(postId);
    const result = await updatePostStatus(
      postId,
      "removed",
      selectedReason,
      adminNote || undefined
    );
    if (result.error) {
      alert(`Error: ${result.error}`);
    }
    setLoading(null);
    setRemovingId(null);
    setSelectedReason("");
    setAdminNote("");
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
        const isRemoving = removingId === post.id;
        const overdue = showAge && isOverdue(post.created_at, 24);

        return (
          <div
            key={post.id}
            className={`bg-white rounded-lg border overflow-hidden ${
              overdue ? "border-red-300" : "border-gray-200"
            }`}
          >
            <div className="px-4 py-3 flex items-start gap-3">
              <button
                onClick={() => setExpandedId(expanded ? null : post.id)}
                className="mt-1 text-gray-400 hover:text-gray-600"
              >
                {expanded ? (
                  <ChevronDown size={16} />
                ) : (
                  <ChevronRight size={16} />
                )}
              </button>

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1 flex-wrap">
                  <span className="font-medium text-sm">
                    {post.author?.username ?? "Unknown"}
                  </span>
                  <span className="text-xs text-gray-400">
                    in {post.neighborhood?.name ?? "\u2014"}
                  </span>
                  <StatusBadge status={post.status} />
                  <span className="text-xs text-gray-400">
                    {post.report_count} report
                    {post.report_count !== 1 ? "s" : ""}
                  </span>
                  {post.reports.length > 0 && (
                    <span className="text-xs text-gray-400">
                      [{[
                        ...Array.from(new Set(post.reports.map((r) => r.reason))),
                      ].join(", ")}]
                    </span>
                  )}
                  {(post.authorStrikeCount ?? 0) > 0 && (
                    <span className="inline-block px-2 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-700">
                      {post.authorStrikeCount} strike
                      {post.authorStrikeCount !== 1 ? "s" : ""}
                    </span>
                  )}
                  {showAge && (
                    <span
                      className={`flex items-center gap-1 text-xs ${
                        overdue ? "text-red-600 font-semibold" : "text-gray-400"
                      }`}
                    >
                      <Clock size={12} />
                      {formatAge(post.created_at)}
                      {overdue && (
                        <span className="flex items-center gap-0.5">
                          <AlertTriangle size={12} />
                          OVERDUE
                        </span>
                      )}
                    </span>
                  )}
                </div>
                <p className="text-sm text-gray-700 line-clamp-2">
                  {post.text}
                </p>
              </div>

              <div className="flex gap-2 shrink-0">
                <button
                  onClick={() => handleRestore(post.id)}
                  disabled={isLoading}
                  className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md bg-green-50 text-green-700 hover:bg-green-100 disabled:opacity-50 transition-colors"
                >
                  <CheckCircle size={14} />
                  Restore
                </button>
                <button
                  onClick={() => {
                    setRemovingId(isRemoving ? null : post.id);
                    setSelectedReason("");
                    setAdminNote("");
                  }}
                  disabled={isLoading}
                  className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md bg-red-50 text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors"
                >
                  <XCircle size={14} />
                  Remove
                </button>
              </div>
            </div>

            {/* Violation reason picker */}
            {isRemoving && (
              <div className="border-t border-gray-100 bg-red-50 px-4 py-3">
                <p className="text-xs font-medium text-gray-700 mb-2">
                  Select violation reason:
                </p>
                <div className="flex flex-wrap gap-2 mb-2">
                  {VIOLATION_REASONS.map((reason) => (
                    <button
                      key={reason}
                      onClick={() => setSelectedReason(reason)}
                      className={`px-3 py-1 text-xs rounded-full border transition-colors ${
                        selectedReason === reason
                          ? "bg-red-600 text-white border-red-600"
                          : "bg-white text-gray-700 border-gray-300 hover:border-red-300"
                      }`}
                    >
                      {reason}
                    </button>
                  ))}
                </div>
                <input
                  type="text"
                  value={adminNote}
                  onChange={(e) => setAdminNote(e.target.value)}
                  placeholder="Optional admin note..."
                  className="w-full text-sm border border-gray-300 rounded-md px-3 py-1.5 mb-2"
                />
                <div className="flex gap-2">
                  <button
                    onClick={() => handleRemoveConfirm(post.id)}
                    disabled={isLoading || !selectedReason}
                    className="px-3 py-1.5 text-xs font-medium rounded-md bg-red-600 text-white hover:bg-red-700 disabled:opacity-50 transition-colors"
                  >
                    Confirm Remove
                  </button>
                  <button
                    onClick={() => setRemovingId(null)}
                    className="px-3 py-1.5 text-xs font-medium rounded-md bg-white text-gray-700 border border-gray-300 hover:bg-gray-50 transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              </div>
            )}

            {expanded && post.reports.length > 0 && (
              <div className="border-t border-gray-100 bg-gray-50 px-4 py-3">
                <p className="text-xs font-medium text-gray-500 mb-2">
                  Reports
                </p>
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
                        <p className="text-gray-600 text-xs">
                          {report.free_text}
                        </p>
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
