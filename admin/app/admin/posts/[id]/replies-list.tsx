"use client";

import { useState } from "react";
import { Trash2 } from "lucide-react";
import { deleteReply } from "./actions";

interface Reply {
  id: string;
  text: string;
  score: number;
  created_at: string;
  parent_reply_id: string | null;
  author?: { username: string; user_number: number } | null;
}

export default function RepliesList({
  replies,
  postId,
}: {
  replies: Reply[];
  postId: string;
}) {
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [confirmId, setConfirmId] = useState<string | null>(null);

  async function handleDelete(replyId: string) {
    setDeletingId(replyId);
    const result = await deleteReply(replyId, postId);
    if (result.error) {
      alert(`Error deleting reply: ${result.error}`);
    }
    setDeletingId(null);
    setConfirmId(null);
  }

  // Build a tree structure for nested replies
  const topLevel = replies.filter((r) => !r.parent_reply_id);
  const childrenMap = new Map<string, Reply[]>();
  for (const reply of replies) {
    if (reply.parent_reply_id) {
      const existing = childrenMap.get(reply.parent_reply_id) ?? [];
      existing.push(reply);
      childrenMap.set(reply.parent_reply_id, existing);
    }
  }

  function renderReply(reply: Reply, depth: number) {
    const children = childrenMap.get(reply.id) ?? [];
    const isConfirming = confirmId === reply.id;
    const isDeleting = deletingId === reply.id;

    return (
      <div key={reply.id} style={{ marginLeft: depth * 24 }}>
        <div className="border border-gray-200 rounded-lg p-3 mb-2 bg-white hover:bg-gray-50">
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2 text-xs text-gray-500 mb-1">
                <span className="font-medium text-gray-700">
                  {reply.author
                    ? `${reply.author.username}#${reply.author.user_number}`
                    : "unknown"}
                </span>
                <span>&middot;</span>
                <span>{new Date(reply.created_at).toLocaleString()}</span>
                <span>&middot;</span>
                <span>score: {reply.score}</span>
              </div>
              <p className="text-sm text-gray-800 whitespace-pre-wrap">
                {reply.text}
              </p>
            </div>
            <div className="flex-shrink-0">
              {isConfirming ? (
                <div className="flex items-center gap-1">
                  <button
                    onClick={() => handleDelete(reply.id)}
                    disabled={isDeleting}
                    className="px-2 py-1 text-xs font-medium rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50 transition-colors"
                  >
                    {isDeleting ? "Deleting..." : "Confirm"}
                  </button>
                  <button
                    onClick={() => setConfirmId(null)}
                    className="px-2 py-1 text-xs font-medium rounded bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
                  >
                    Cancel
                  </button>
                </div>
              ) : (
                <button
                  onClick={() => setConfirmId(reply.id)}
                  className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded bg-red-50 text-red-700 hover:bg-red-100 transition-colors"
                >
                  <Trash2 size={12} />
                  Delete
                </button>
              )}
            </div>
          </div>
        </div>
        {children.map((child) => renderReply(child, depth + 1))}
      </div>
    );
  }

  return (
    <div className="space-y-1">
      {topLevel.map((reply) => renderReply(reply, 0))}
    </div>
  );
}
