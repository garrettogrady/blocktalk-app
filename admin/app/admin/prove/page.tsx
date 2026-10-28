import { supabaseAdmin } from "@/lib/supabase-admin";
import type { SurveyResponse, SurveyQuestion, RantResponse } from "@/lib/types";
import StatCard from "@/components/stat-card";
import ProveTable from "./prove-table";
import RantTable from "./rant-table";

export const dynamic = "force-dynamic";

const SOURCES = ["p1", "p2", "p3", "direct"] as const;
const TIERS = ["CITY SLICKER", "BLOCKTALKER", "TRANSPLANT", "TOURIST"] as const;

async function getResponses(): Promise<SurveyResponse[]> {
  const { data, error } = await supabaseAdmin
    .from("survey_responses").select("*").order("created_at", { ascending: false }).limit(5000);
  if (error) { console.error("survey_responses fetch error:", error); return []; }
  return (data ?? []) as SurveyResponse[];
}

async function getQuestions(): Promise<SurveyQuestion[]> {
  const { data, error } = await supabaseAdmin.from("survey_questions").select("*").order("ord");
  if (error) { console.error("survey_questions fetch error:", error); return []; }
  return (data ?? []) as SurveyQuestion[];
}

async function getRants(): Promise<RantResponse[]> {
  const { data, error } = await supabaseAdmin
    .from("rant_responses").select("*").order("created_at", { ascending: false }).limit(5000);
  if (error) { console.error("rant_responses fetch error:", error); return []; }
  return (data ?? []) as RantResponse[];
}

/** Scan counts per source. survey_scans is small (one row per landing page load). */
async function getScanCounts(): Promise<Record<string, number>> {
  const counts: Record<string, number> = { p1: 0, p2: 0, p3: 0, direct: 0 };
  const { data, error } = await supabaseAdmin.from("survey_scans").select("src").limit(100000);
  if (error) { console.error("survey_scans fetch error:", error); return counts; }
  for (const row of data ?? []) {
    const src = (row as { src: string }).src;
    counts[src] = (counts[src] ?? 0) + 1;
  }
  return counts;
}

export default async function ProvePage() {
  const [responses, questions, rants, scans] = await Promise.all([getResponses(), getQuestions(), getRants(), getScanCounts()]);

  const byTier: Record<string, number> = {};
  const bySrc: Record<string, number> = { p1: 0, p2: 0, p3: 0, direct: 0 };
  let purist = 0;
  for (const r of responses) {
    byTier[r.tier] = (byTier[r.tier] ?? 0) + 1;
    if (r.quiz === "regular") bySrc[r.src] = (bySrc[r.src] ?? 0) + 1;
    if (r.quiz === "purist") purist++;
  }
  const contacted = responses.filter((r) => r.contacted).length;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold">Prove It</h2>
        <span className="text-sm text-gray-500">
          {responses.length} quiz response{responses.length !== 1 ? "s" : ""} ({purist} purist) · {contacted} contacted · {rants.length} rant take{rants.length !== 1 ? "s" : ""}
        </span>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-4">
        <StatCard label="Total responses" value={responses.length} />
        {TIERS.map((t) => (
          <StatCard key={t} label={t} value={byTier[t] ?? 0}
            accent={t === "CITY SLICKER" ? "green" : t === "TOURIST" ? "red" : "default"} />
        ))}
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-4 mb-6">
        <p className="text-sm font-medium text-gray-500 mb-3">Scans vs completions by sticker (regular quiz)</p>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {SOURCES.map((s) => {
            const sc = scans[s] ?? 0;
            const done = bySrc[s] ?? 0;
            const rate = sc > 0 ? Math.round((done / sc) * 100) : 0;
            return (
              <div key={s} className="border border-gray-100 rounded-md p-3">
                <p className="font-mono text-xs text-gray-500 uppercase">{s}</p>
                <p className="text-lg font-bold mt-1">{done} <span className="text-sm font-normal text-gray-500">/ {sc} scans</span></p>
                <p className="text-xs text-gray-500">{sc > 0 ? `${rate}% completed` : "no scans yet"}</p>
              </div>
            );
          })}
        </div>
      </div>

      <h3 className="text-lg font-semibold mb-3">Quiz responses</h3>
      <ProveTable responses={responses} questions={questions} />

      <h3 className="text-lg font-semibold mt-10 mb-3">Rant tab takes</h3>
      <RantTable rants={rants} />
    </div>
  );
}
