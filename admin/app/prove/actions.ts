"use server";

import { revalidatePath } from "next/cache";
import { supabaseAdmin } from "@/lib/supabase-admin";

/** Flip the "contacted" flag after Matt has reached out to a respondent. */
export async function setContacted(id: string, contacted: boolean) {
  const { error } = await supabaseAdmin
    .from("survey_responses")
    .update({ contacted })
    .eq("id", id);
  if (error) return { error: error.message };
  revalidatePath("/prove");
  return { ok: true };
}
