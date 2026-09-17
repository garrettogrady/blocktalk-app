import { supabaseAdmin } from "@/lib/supabase-admin";
import PaginatedPostsTable from "./paginated-posts-table";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 25;

interface Props {
  searchParams: Promise<{ page?: string }>;
}

export default async function PostsPage({ searchParams }: Props) {
  const params = await searchParams;
  const page = Math.max(1, parseInt(params.page ?? "1", 10));
  const offset = (page - 1) * PAGE_SIZE;

  const [{ data, count }, ] = await Promise.all([
    supabaseAdmin
      .from("posts")
      .select(
        "id, text, score, reply_count, status, created_at, author:users!posts_user_id_fkey(username, user_number), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name)",
        { count: "exact" }
      )
      .order("created_at", { ascending: false })
      .range(offset, offset + PAGE_SIZE - 1),
  ]);

  const posts = (data ?? []).map((row: any) => ({
    ...row,
    author: Array.isArray(row.author) ? row.author[0] ?? null : row.author,
    neighborhood: Array.isArray(row.neighborhood)
      ? row.neighborhood[0] ?? null
      : row.neighborhood,
  }));

  const totalPages = Math.ceil((count ?? 0) / PAGE_SIZE);

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Posts</h2>
      <p className="text-sm text-gray-500 mb-4">
        {count ?? 0} total posts &middot; Page {page} of {totalPages}
      </p>
      <PaginatedPostsTable posts={posts} />
      <Pagination currentPage={page} totalPages={totalPages} />
    </div>
  );
}

function Pagination({
  currentPage,
  totalPages,
}: {
  currentPage: number;
  totalPages: number;
}) {
  if (totalPages <= 1) return null;

  const pages: (number | "...")[] = [];
  for (let i = 1; i <= totalPages; i++) {
    if (
      i === 1 ||
      i === totalPages ||
      (i >= currentPage - 2 && i <= currentPage + 2)
    ) {
      pages.push(i);
    } else if (pages[pages.length - 1] !== "...") {
      pages.push("...");
    }
  }

  return (
    <div className="flex items-center justify-center gap-1 mt-6">
      {currentPage > 1 && (
        <a
          href={`/posts?page=${currentPage - 1}`}
          className="px-3 py-1.5 text-sm rounded-md bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
        >
          Previous
        </a>
      )}
      {pages.map((p, i) =>
        p === "..." ? (
          <span key={`ellipsis-${i}`} className="px-2 text-gray-400">
            &hellip;
          </span>
        ) : (
          <a
            key={p}
            href={`/posts?page=${p}`}
            className={`px-3 py-1.5 text-sm rounded-md transition-colors ${
              p === currentPage
                ? "bg-blue-600 text-white"
                : "bg-gray-100 text-gray-700 hover:bg-gray-200"
            }`}
          >
            {p}
          </a>
        )
      )}
      {currentPage < totalPages && (
        <a
          href={`/posts?page=${currentPage + 1}`}
          className="px-3 py-1.5 text-sm rounded-md bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
        >
          Next
        </a>
      )}
    </div>
  );
}
