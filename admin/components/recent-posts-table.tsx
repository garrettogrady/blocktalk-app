"use client";

import { useState } from "react";
import { XCircle } from "lucide-react";
import RemoveDialog from "./remove-dialog";

interface RecentPost {
  id: string;
  text: string;
  score: number;
  reply_count: number;
  status: string;
  created_at: string;
  author?: { username: string; user_number: number } | null;
  neighborhood?: { name: string } | null;
}

export default function RecentPostsTable({
  posts,
}: {
  posts: RecentPost[];
}) {
  const [removingPost, setRemovingPost] = useState<RecentPost | null>(null);

  return (
    <>
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
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Actions
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {posts.map((post) => (
              <tr key={post.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">
                  {post.author?.username ?? "\u2014"}
                </td>
                <td className="px-4 py-3 max-w-md truncate text-gray-600">
                  {post.text}
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {post.neighborhood?.name ?? "\u2014"}
                </td>
                <td className="px-4 py-3">{post.score}</td>
                <td className="px-4 py-3">
                  <StatusBadge status={post.status} />
                </td>
                <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                  {new Date(post.created_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3">
                  {post.status !== "removed" && (
                    <button
                      onClick={() => setRemovingPost(post)}
                      className="flex items-center gap-1 px-2 py-1 text-xs font-medium rounded bg-red-50 text-red-700 hover:bg-red-100 transition-colors"
                    >
                      <XCircle size={12} />
                      Remove
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {removingPost && (
        <RemoveDialog
          postId={removingPost.id}
          postText={removingPost.text}
          onClose={() => setRemovingPost(null)}
        />
      )}
    </>
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
