"use client";

import { useState } from "react";
import { ChevronDown, ChevronRight, CheckCircle, XCircle } from "lucide-react";
import { updateAppealStatus } from "./actions";
import type { Appeal } from "@/lib/types";

export default function AppealsTable({ appeals }: { appeals: Appeal[] }) {
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [loading, setLoading] = useState<string | null>(null);

  async function handleAction(appealId: string, newStatus: "accepted" | "rejected") {
    setLoading(appealId);
    const result = await updateAppealStatus(appealId, newStatus);
    if (result.error) {
      alert(`Error: ${result.error}`);
    }
    setLoading(null);
  }

  if (appeals.length === 0) {
    return (
      <div className="bg-white rounded-lg border border-gray-200 p-8 text-center text-gray-500">
        No appeals to review.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {appeals.map((appeal) => {
        const expanded = expandedId === appeal.id;
        const isLoading = loading === appeal.id;
        const isPending = appeal.status === "pending";

        return (
          <div
            key={appeal.id}
            className="bg-white rounded-lg border border-gray-200 overflow-hidden"
          >
            <div className="px-4 py-3 flex items-start gap-3">
              <button
                onClick={() => setExpandedId(expanded ? null : appeal.id)}
                className="mt-1 text-gray-400 hover:text-gray-600"
              >
                {expanded ? <ChevronDown size={16} /> : <ChevronRight size={16} />}
              </button>

              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 mb-1">
                  <span className="font-medium text-sm">
                    {appeal.user?.username ?? "Unknown"}
                    {appeal.user?.user_number != null && (
                      <span className="text-gray-400 ml-1">#{appeal.user.user_number}</span>
                    )}
                  </span>
                  <AppealStatusBadge status={appeal.status} />
                  <span className="text-xs text-gray-400">
                    {new Date(appeal.created_at).toLocaleDateString()}
                  </span>
                </div>
                <p className="text-sm text-gray-700 line-clamp-2">{appeal.appeal_text}</p>
              </div>

              {isPending && (
                <div className="flex gap-2 shrink-0">
                  <button
                    onClick={() => handleAction(appeal.id, "accepted")}
                    disabled={isLoading}
                    className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md bg-green-50 text-green-700 hover:bg-green-100 disabled:opacity-50 transition-colors"
                  >
                    <CheckCircle size={14} />
                    Accept
                  </button>
                  <button
                    onClick={() => handleAction(appeal.id, "rejected")}
                    disabled={isLoading}
                    className="flex items-center gap-1 px-3 py-1.5 text-xs font-medium rounded-md bg-red-50 text-red-700 hover:bg-red-100 disabled:opacity-50 transition-colors"
                  >
                    <XCircle size={14} />
                    Reject
                  </button>
                </div>
              )}
            </div>

            {expanded && appeal.post && (
              <div className="border-t border-gray-100 bg-gray-50 px-4 py-3">
                <p className="text-xs font-medium text-gray-500 mb-2">Original Post</p>
                <div className="bg-white rounded border border-gray-200 px-3 py-2 text-sm">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-medium text-xs">
                      {appeal.post.author?.username ?? "Unknown"}
                    </span>
                    <span className="text-xs text-gray-400">
                      in {appeal.post.neighborhood?.name ?? "—"}
                    </span>
                    <PostStatusBadge status={appeal.post.status} />
                  </div>
                  <p className="text-gray-700 text-sm">{appeal.post.text}</p>
                </div>
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}

function AppealStatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    pending: "bg-yellow-100 text-yellow-700",
    accepted: "bg-green-100 text-green-700",
    rejected: "bg-red-100 text-red-700",
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

function PostStatusBadge({ status }: { status: string }) {
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
