import { supabaseAdmin } from "@/lib/supabase-admin";
import PostSearch from "@/components/post-search";
import { searchPosts } from "./actions";

export const dynamic = "force-dynamic";

async function getNeighborhoods() {
  const { data } = await supabaseAdmin
    .from("neighborhoods")
    .select("id, name")
    .order("name");
  return data ?? [];
}

export default async function SearchPage() {
  const neighborhoods = await getNeighborhoods();

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Post Search</h2>
      <PostSearch neighborhoods={neighborhoods} searchAction={searchPosts} />
    </div>
  );
}
