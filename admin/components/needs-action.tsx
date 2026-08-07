"use client";

import Link from "next/link";
import {
  Clock,
  AlertTriangle,
  CheckCircle,
  XCircle,
  Shield,
  Scale,
} from "lucide-react";
import { updatePostStatus } from "@/app/moderation/actions";
import { updateAppealStatus } from "@/app/appeals/actions";
import { useState } from "react";

interface ActionPost {
  id: string;
  text: string;
  status: string;
  created_at: string;
  report_count: number;
  author?: { username: string } | null;
  neighborhood?: { name: string } | null;
  reports: { reason: string }[];
}

interface ActionAppeal {
  id: string;
  appeal_text: string;
  created_at: string;
  user?: { username: string; user_number: number } | null;
}

interface NeedsActionProps {
  p1Posts: ActionPost[];
  p1Total: number;
  p2Count: number;
  pendingAppeals: ActionAppeal[];
  appealsTotal: number;
}

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

export default function NeedsAction({
  p1Posts,
  p1Total,
  p2Count,
  pendingAppeals,
  appealsTotal,
}: NeedsActionProps) {
  const [loading, setLoading] = useState<string | null>(null);
  const hasItems =
    p1Posts.length > 0 || p2Count > 0 || pendingAppeals.length > 0;

  async function handlePostAction(
    postId: string,
    newStatus: "live" | "removed"
  ) {
    setLoading(postId);
    await updatePostStatus(postId, newStatus);
    setLoading(null);
  }

  async function handleAppealAction(
    appealId: string,
    newStatus: "accepted" | "rejected"
  ) {
    setLoading(appealId);
    await updateAppealStatus(appealId, newStatus);
    setLoading(null);
  }

  if (!hasItems) {
    return (
      <div className="bg-green-50 border border-green-200 rounded-lg p-6 text-center text-green-700 text-sm font-medium">
        <CheckCircle size={20} className="inline-block mb-1 mr-1" />
        Nothing needs action.
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* P1 reported posts */}
      {p1Posts.length > 0 && (
        <div className="bg-white rounded-lg border border-red-200 overflow-hidden">
          <div className="px-4 py-2 bg-red-50 border-b border-red-200 flex items-center gap-2">
            <Shield size={14} className="text-red-600" />
            <span className="text-sm font-semibold text-red-800">
              Priority 1 Reports
            </span>
          </div>
          <div className="divide-y divide-gray-100">
            {p1Posts.map((post) => {
              const diffMs =
                Date.now() - new Date(post.created_at).getTime();
              const overdue = diffMs > 24 * 60 * 60 * 1000;
              const isLoading = loading === post.id;

              return (
                <div
                  key={post.id}
                  className="px-4 py-3 flex items-center gap-3"
                >
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-medium">
                        {post.author?.username ?? "Unknown"}
                      </span>
                      <span className="text-xs text-gray-400">
                        {post.neighborhood?.name ?? ""}
                      </span>
                      <span className="text-xs text-gray-400">
                        [{[
                          ...new Set(post.reports.map((r) => r.reason)),
                        ].join(", ")}]
                      </span>
                      <span
                        className={`flex items-center gap-1 text-xs ${
                          overdue
                            ? "text-red-600 font-semibold"
                            : "text-gray-400"
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
                    </div>
                    <p className="text-sm text-gray-600 truncate mt-0.5">
                      {post.text}
                    </p>
                  </div>
                  <div className="flex gap-2 shrink-0">
                    <button
                      onClick={() => handlePostAction(post.id, "live")}
                      disabled={isLoading}
                      className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded bg-green-50 text-green-700 hover:bg-green-100 disabled:opacity-50"
                    >
                      <CheckCircle size={12} />
                      Restore
                    </button>
                    <Link
                      href="/moderation"
                      className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded bg-gray-100 text-gray-700 hover:bg-gray-200"
                    >
                      Review
                    </Link>
                  </div>
                </div>
              );
            })}
          </div>
          {p1Total > p1Posts.length && (
            <div className="px-4 py-2 border-t border-gray-100 bg-gray-50">
              <Link
                href="/moderation"
                className="text-xs text-blue-600 hover:underline"
              >
                View all {p1Total} P1 reports
              </Link>
            </div>
          )}
        </div>
      )}

      {/* P2 summary */}
      {p2Count > 0 && (
        <Link
          href="/moderation"
          className="block bg-white rounded-lg border border-yellow-200 px-4 py-3 hover:bg-yellow-50 transition-colors"
        >
          <div className="flex items-center gap-2">
            <Shield size={14} className="text-yellow-600" />
            <span className="text-sm text-yellow-800">
              <span className="font-semibold">{p2Count}</span> Priority 2
              report{p2Count !== 1 ? "s" : ""} waiting
            </span>
          </div>
        </Link>
      )}

      {/* Pending appeals */}
      {pendingAppeals.length > 0 && (
        <div className="bg-white rounded-lg border border-yellow-200 overflow-hidden">
          <div className="px-4 py-2 bg-yellow-50 border-b border-yellow-200 flex items-center gap-2">
            <Scale size={14} className="text-yellow-700" />
            <span className="text-sm font-semibold text-yellow-800">
              Pending Appeals
            </span>
          </div>
          <div className="divide-y divide-gray-100">
            {pendingAppeals.map((appeal) => {
              const diffMs =
                Date.now() - new Date(appeal.created_at).getTime();
              const overdue = diffMs > 48 * 60 * 60 * 1000;
              const isLoading = loading === appeal.id;

              return (
                <div
                  key={appeal.id}
                  className="px-4 py-3 flex items-center gap-3"
                >
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="text-sm font-medium">
                        {appeal.user?.username ?? "Unknown"}
                      </span>
                      <span
                        className={`flex items-center gap-1 text-xs ${
                          overdue
                            ? "text-red-600 font-semibold"
                            : "text-gray-400"
                        }`}
                      >
                        <Clock size={12} />
                        {formatAge(appeal.created_at)}
                        {overdue && (
                          <span className="flex items-center gap-0.5">
                            <AlertTriangle size={12} />
                            OVERDUE
                          </span>
                        )}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 truncate mt-0.5">
                      {appeal.appeal_text}
                    </p>
                  </div>
                  <div className="flex gap-2 shrink-0">
                    <button
                      onClick={() =>
                        handleAppealAction(appeal.id, "accepted")
                      }
                      disabled={isLoading}
                      className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded bg-green-50 text-green-700 hover:bg-green-100 disabled:opacity-50"
                    >
                      <CheckCircle size={12} />
                      Accept
                    </button>
                    <button
                      onClick={() =>
                        handleAppealAction(appeal.id, "rejected")
                      }
                      disabled={isLoading}
                      className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded bg-red-50 text-red-700 hover:bg-red-100 disabled:opacity-50"
                    >
                      <XCircle size={12} />
                      Reject
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
          {appealsTotal > pendingAppeals.length && (
            <div className="px-4 py-2 border-t border-gray-100 bg-gray-50">
              <Link
                href="/appeals"
                className="text-xs text-blue-600 hover:underline"
              >
                View all {appealsTotal} pending appeals
              </Link>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
