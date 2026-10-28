"use client";

import { useMemo, useState } from "react";
import { ChevronDown, ChevronRight, Download } from "lucide-react";
import { setContacted } from "./actions";
import type { SurveyResponse, SurveyQuestion } from "@/lib/types";

const TIERS = ["CITY SLICKER", "BLOCKTALKER", "TRANSPLANT", "TOURIST"];
const MAX: Record<string, number> = { regular: 11, purist: 17 };

function csvCell(v: unknown): string {
  if (v === null || v === undefined) return "";
  const s = String(v);
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

function tierClass(tier: string): string {
  switch (tier) {
    case "CITY SLICKER": return "bg-green-100 text-green-800";
    case "BLOCKTALKER": return "bg-blue-100 text-blue-800";
    case "TRANSPLANT": return "bg-yellow-100 text-yellow-800";
    default: return "bg-gray-100 text-gray-700";
  }
}

export default function ProveTable({ responses, questions }: { responses: SurveyResponse[]; questions: SurveyQuestion[] }) {
  const [quiz, setQuiz] = useState("");
  const [tier, setTier] = useState("");
  const [hood, setHood] = useState("");
  const [contactedFilter, setContactedFilter] = useState("");
  const [expanded, setExpanded] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  // Optimistic contacted flags so the toggle feels instant.
  const [overrides, setOverrides] = useState<Record<string, boolean>>({});

  const hoods = useMemo(() => Array.from(new Set(responses.map((r) => r.neighborhood))).sort(), [responses]);
  // Question order and labels per quiz, from survey_questions.
  const qByQuiz = useMemo(() => {
    const m: Record<string, SurveyQuestion[]> = {};
    for (const q of questions) (m[q.quiz] ??= []).push(q);
    for (const k of Object.keys(m)) m[k].sort((a, b) => a.ord - b.ord);
    return m;
  }, [questions]);
  // Every question id across both quizzes, for CSV columns.
  const allQ = useMemo(() => Array.from(new Set(questions.sort((a, b) => a.ord - b.ord).map((q) => q.q))), [questions]);

  const rows = useMemo(() => responses.filter((r) => {
    const isContacted = overrides[r.id] ?? r.contacted;
    if (quiz && r.quiz !== quiz) return false;
    if (tier && r.tier !== tier) return false;
    if (hood && r.neighborhood !== hood) return false;
    if (contactedFilter === "yes" && !isContacted) return false;
    if (contactedFilter === "no" && isContacted) return false;
    return true;
  }), [responses, quiz, tier, hood, contactedFilter, overrides]);

  async function toggle(r: SurveyResponse) {
    const next = !(overrides[r.id] ?? r.contacted);
    setBusy(r.id);
    setOverrides((o) => ({ ...o, [r.id]: next }));
    const result = await setContacted(r.id, next);
    if ("error" in result && result.error) {
      setOverrides((o) => ({ ...o, [r.id]: !next }));
      alert(`Error: ${result.error}`);
    }
    setBusy(null);
  }

  function exportCsv() {
    const fixed = ["created_at", "quiz", "email", "neighborhood", "phone", "sms_consent", "score", "tier", "src", "contacted"];
    const qcols = allQ.flatMap((q) => [`${q}_choice`, `${q}_text`]);
    const header = [...fixed, ...qcols, "user_agent", "id"];
    const lines = [header.join(",")].concat(responses.map((r) => {
      const vals: unknown[] = [r.created_at, r.quiz, r.email, r.neighborhood, r.phone, r.sms_consent, r.score, r.tier, r.src, overrides[r.id] ?? r.contacted];
      for (const q of allQ) { vals.push(r.answers?.[q]?.choice ?? ""); vals.push(r.answers?.[q]?.text ?? ""); }
      vals.push(r.user_agent, r.id);
      return vals.map(csvCell).join(",");
    }));
    const blob = new Blob(["﻿" + lines.join("\n")], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `prove-it-responses-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
      <div className="flex flex-wrap items-center gap-3 px-4 py-3 border-b border-gray-200 bg-gray-50">
        <select value={quiz} onChange={(e) => setQuiz(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">Both quizzes</option><option value="regular">Regular</option><option value="purist">Purist</option>
        </select>
        <select value={tier} onChange={(e) => setTier(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">All tiers</option>
          {TIERS.map((t) => <option key={t} value={t}>{t}</option>)}
        </select>
        <select value={hood} onChange={(e) => setHood(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">All neighborhoods</option>
          {hoods.map((h) => <option key={h} value={h}>{h}</option>)}
        </select>
        <select value={contactedFilter} onChange={(e) => setContactedFilter(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">Contacted: any</option><option value="no">Not yet contacted</option><option value="yes">Contacted</option>
        </select>
        <span className="text-sm text-gray-500">{rows.length} shown</span>
        <button onClick={exportCsv} className="ml-auto inline-flex items-center gap-2 text-sm font-medium text-gray-700 border border-gray-300 rounded-md px-3 py-1.5 bg-white hover:bg-gray-50">
          <Download size={14} /> Export CSV (all {responses.length})
        </button>
      </div>

      {rows.length === 0 ? (
        <div className="p-8 text-center text-gray-500">No responses match.</div>
      ) : (
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="w-8"></th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">When</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Quiz</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Email</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Phone</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Neighborhood</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Score</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Tier</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Src</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Contacted</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {rows.map((r) => {
              const open = expanded === r.id;
              const isContacted = overrides[r.id] ?? r.contacted;
              const qs = qByQuiz[r.quiz] ?? [];
              return (
                <Rows key={r.id}>
                  <tr className="hover:bg-gray-50 cursor-pointer" onClick={() => setExpanded(open ? null : r.id)}>
                    <td className="pl-3 text-gray-400">{open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}</td>
                    <td className="px-3 py-3 text-gray-500 whitespace-nowrap">{new Date(r.created_at).toLocaleString()}</td>
                    <td className="px-3 py-3 font-mono text-xs text-gray-600">{r.quiz}</td>
                    <td className="px-3 py-3 font-medium">{r.email}</td>
                    <td className="px-3 py-3 text-gray-600 whitespace-nowrap">{r.phone ? `${r.phone}${r.sms_consent ? " (sms ok)" : ""}` : "none"}</td>
                    <td className="px-3 py-3 text-gray-600 whitespace-nowrap">{r.neighborhood}</td>
                    <td className="px-3 py-3 font-mono">{r.score}/{MAX[r.quiz] ?? "?"}</td>
                    <td className="px-3 py-3"><span className={`inline-block rounded px-2 py-0.5 text-xs font-semibold ${tierClass(r.tier)}`}>{r.tier}</span></td>
                    <td className="px-3 py-3 font-mono text-xs text-gray-500">{r.src}</td>
                    <td className="px-3 py-3" onClick={(e) => e.stopPropagation()}>
                      <button onClick={() => toggle(r)} disabled={busy === r.id}
                        className={`rounded-md px-2.5 py-1 text-xs font-medium border ${isContacted ? "bg-green-50 border-green-300 text-green-800" : "bg-white border-gray-300 text-gray-600 hover:bg-gray-50"}`}>
                        {isContacted ? "Contacted" : "Mark contacted"}
                      </button>
                    </td>
                  </tr>
                  {open && (
                    <tr className="bg-gray-50">
                      <td></td>
                      <td colSpan={9} className="px-3 py-4">
                        <div className="grid md:grid-cols-2 gap-4 text-sm">
                          {qs.map((q) => {
                            const a = r.answers?.[q.q];
                            return (
                              <div key={q.q}>
                                <p className="font-mono text-xs text-gray-500 uppercase">{q.ord}. {q.prompt}</p>
                                {a?.choice && <p className="text-gray-900">{a.choice}</p>}
                                {a?.text ? (
                                  <p className="mt-1 whitespace-pre-wrap text-gray-900 bg-amber-50 border border-amber-100 rounded px-3 py-2">{a.text}</p>
                                ) : !a?.choice ? <p className="text-gray-400">(blank)</p> : null}
                              </div>
                            );
                          })}
                        </div>
                        <div className="mt-4 flex flex-wrap gap-x-6 gap-y-1 text-xs text-gray-500 font-mono">
                          <span>phone: {r.phone ?? "none"}</span>
                          <span>sms consent: {r.sms_consent ? "yes" : "no"}</span>
                          <span>src: {r.src}</span>
                          <span className="truncate max-w-md" title={r.user_agent ?? ""}>ua: {r.user_agent ?? "none"}</span>
                        </div>
                      </td>
                    </tr>
                  )}
                </Rows>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}

/** Lets a row and its expansion share one key without an extra DOM wrapper. */
function Rows({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
