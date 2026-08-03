import { supabaseAdmin } from "@/lib/supabase-admin";
import AppealsTable from "./appeals-table";
import type { Appeal } from "@/lib/types";

export const dynamic = "force-dynamic";

async function getAppeals(): Promise<Appeal[]> {
  const { data, error } = await supabaseAdmin
    .from("appeals")
    .select(
      "*, user:users!appeals_user_id_fkey(username, user_number), post:posts!appeals_post_id_fkey(*, author:users!posts_user_id_fkey(username, user_number), neighborhood:neighborhoods!posts_neighborhood_id_fkey(name))"
    )
    .order("created_at", { ascending: false });

  if (error || !data) return [];

  return data as Appeal[];
}

export default async function AppealsPage() {
  const appeals = await getAppeals();
  const pendingCount = appeals.filter((a) => a.status === "pending").length;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">Appeals</h2>
        <span className="text-sm text-gray-500">
          {pendingCount} pending appeal{pendingCount !== 1 ? "s" : ""}
        </span>
      </div>
      <AppealsTable appeals={appeals} />
    </div>
  );
}
