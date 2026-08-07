import { supabaseAdmin } from "@/lib/supabase-admin";

export const dynamic = "force-dynamic";

async function getUsers() {
  const { data: users } = await supabaseAdmin
    .from("users")
    .select(
      "id, username, user_number, is_seed, created_at, neighborhood:neighborhoods!users_home_neighborhood_id_fkey(name, borough)"
    )
    .order("created_at", { ascending: false });

  if (!users) return [];

  // Get post counts per user
  const { data: postCounts } = await supabaseAdmin
    .from("posts")
    .select("user_id");

  const postCountMap = new Map<string, number>();
  for (const p of postCounts ?? []) {
    postCountMap.set(p.user_id, (postCountMap.get(p.user_id) ?? 0) + 1);
  }

  // Get reply counts per user
  const { data: replyCounts } = await supabaseAdmin
    .from("replies")
    .select("user_id");

  const replyCountMap = new Map<string, number>();
  for (const r of replyCounts ?? []) {
    replyCountMap.set(r.user_id, (replyCountMap.get(r.user_id) ?? 0) + 1);
  }

  return users.map((user: any) => ({
    ...user,
    postCount: postCountMap.get(user.id) ?? 0,
    replyCount: replyCountMap.get(user.id) ?? 0,
  }));
}

export default async function UsersPage() {
  const users = await getUsers();

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">Users</h2>
        <span className="text-sm text-gray-500">
          {users.length} total user{users.length !== 1 ? "s" : ""}
        </span>
      </div>

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Username
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Type
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                #
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Home Neighborhood
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Borough
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Posts
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Replies
              </th>
              <th className="text-left px-4 py-3 font-medium text-gray-500">
                Joined
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {users.map((user: any) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium">{user.username}</td>
                <td className="px-4 py-3">
                  {user.is_seed ? (
                    <span className="inline-block px-2 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-700">
                      Seed
                    </span>
                  ) : (
                    <span className="inline-block px-2 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-700">
                      Organic
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-gray-500">{user.user_number}</td>
                <td className="px-4 py-3 text-gray-600">
                  {user.neighborhood?.name ?? "—"}
                </td>
                <td className="px-4 py-3 text-gray-500">
                  {user.neighborhood?.borough ?? "—"}
                </td>
                <td className="px-4 py-3">{user.postCount}</td>
                <td className="px-4 py-3">{user.replyCount}</td>
                <td className="px-4 py-3 text-gray-500 whitespace-nowrap">
                  {new Date(user.created_at).toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
