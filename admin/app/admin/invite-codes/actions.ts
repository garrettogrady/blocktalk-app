"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase-admin";

export async function generateBatch(count: number) {
  const { data, error } = await supabaseAdmin.rpc("generate_admin_invite_codes", {
    batch_size: count,
  });

  if (error) return { error: error.message };

  revalidatePath("/admin/invite-codes");
  return { codes: data };
}

export async function revokeCode(code: string) {
  const { error } = await supabaseAdmin
    .from("invite_codes")
    .delete()
    .eq("code", code)
    .is("redeemed_by", null);

  if (error) return { error: error.message };

  revalidatePath("/admin/invite-codes");
  return { success: true };
}

export async function fetchAllCodes() {
  const { data, error } = await supabaseAdmin
    .from("invite_codes")
    .select("code, redeemed_by, redeemed_at, created_at, created_by")
    .order("created_at", { ascending: false });

  if (error) return { error: error.message };
  return { codes: data };
}
