"use client";

import { useState, useTransition } from "react";
import { Search, XCircle } from "lucide-react";
import RemoveDialog from "./remove-dialog";

interface SearchPost {
  id: string;
  text: string;
  score: number;
  reply_count: number;
  status: string;
  created_at: string;
  author?: { username: string; user_number: number } | null;
  neighborhood?: { name: string } | null;
}

interface PostSearchProps {
  neighborhoods: { id: string; name: string }[];
  searchAction: (
    query: string,
    neighborhoodId: string,
    status: string
  ) => Promise<SearchPost[]>;
}

export default function PostSearch({
  neighborhoods,
  searchAction,
}: PostSearchProps) {
  const [query, setQuery] = useState("");
  const [neighborhoodId, setNeighborhoodId] = useState("");
  const [status, setStatus] = useState("");
  const [results, setResults] = useState<SearchPost[]>([]);
  const [searched, setSearched] = useState(false);
  const [isPending, startTransition] = useTransition();
  const [removingPost, setRemovingPost] = useState<SearchPost | null>(null);

  function handleSearch() {
    if (!query.trim() && !neighborhoodId && !status) return;
    startTransition(async () => {
      const data = await searchAction(query, neighborhoodId, status);
      setResults(data);
      setSearched(true);
    });
  }

  return (
    <div>
      <div className="flex gap-2 mb-4 flex-wrap">
        <div className="flex-1 min-w-[200px]">
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSearch()}
            placeholder="Search post text..."
            className="w-full text-sm border border-gray-300 rounded-md px-3 py-2"
          />
        </div>
        <select
          value={neighborhoodId}
          onChange={(e) => setNeighborhoodId(e.target.value)}
          className="text-sm border border-gray-300 rounded-md px-3 py-2"
        >
          <option value="">All neighborhoods</option>
          {neighborhoods.map((n) => (
            <option key={n.id} value={n.id}>
              {n.name}
            </option>
          ))}
        </select>
        <select
          value={status}
          onChange={(e) => setStatus(e.target.value)}
          className="text-sm border border-gray-300 rounded-md px-3 py-2"
        >
          <option value="">All statuses</option>
          <option value="live">Live</option>
          <option value="under_review">Under Review</option>
          <option value="removed">Removed</option>
        </select>
        <button
          onClick={handleSearch}
          disabled={isPending}
          className="flex items-center gap-1 px-4 py-2 text-sm font-medium rounded-md bg-gray-900 text-white hover:bg-gray-700 disabled:opacity-50 transition-colors"
        >
          <Search size={14} />
          {isPending ? "Searching..." : "Search"}
        </button>
      </div>

      {searched && (
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          {results.length === 0 ? (
            <div className="p-6 text-center text-gray-500 text-sm">
              No posts found.
            </div>
          ) : (
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
                {results.map((post) => (
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
          )}
        </div>
      )}

      {removingPost && (
        <RemoveDialog
          postId={removingPost.id}
          postText={removingPost.text}
          onClose={() => {
            setRemovingPost(null);
            handleSearch();
          }}
        />
      )}
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
