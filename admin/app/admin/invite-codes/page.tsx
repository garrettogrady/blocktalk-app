import { supabaseAdmin } from "@/lib/supabase-admin";
import InviteTable from "./invite-table";

export const dynamic = "force-dynamic";

export default async function InviteCodesPage() {
  const { data: codes } = await supabaseAdmin
    .from("invite_codes")
    .select("code, redeemed_by, redeemed_at, created_at, created_by")
    .order("created_at", { ascending: false });

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">Invite Codes</h1>
      <InviteTable codes={codes ?? []} />
    </div>
  );
}
