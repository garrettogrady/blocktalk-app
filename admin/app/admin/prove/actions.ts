"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase-admin";

/** Flip "contacted" on a quiz response after Matt has reached out. */
export async function setContacted(id: string, contacted: boolean) {
  const { error } = await supabaseAdmin.from("survey_responses").update({ contacted }).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/admin/prove");
  return { ok: true };
}

/** Same, for a rant-tab take. */
export async function setRantContacted(id: string, contacted: boolean) {
  const { error } = await supabaseAdmin.from("rant_responses").update({ contacted }).eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/admin/prove");
  return { ok: true };
}
