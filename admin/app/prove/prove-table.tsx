"use client";

import { useMemo, useState } from "react";
import { ChevronDown, ChevronRight, Download } from "lucide-react";
import { setContacted } from "./actions";
import type { SurveyResponse } from "@/lib/types";

const TIERS = ["CITY SLICKER", "BLOCKTALKER", "TRANSPLANT", "TOURIST"];

const CSV_COLUMNS: (keyof SurveyResponse)[] = [
  "created_at", "email", "neighborhood", "phone", "sms_consent", "score", "tier", "src",
  "contacted", "q1_choice", "q1_text", "q2_choice", "q2_text", "q3_choice", "q4_choice",
  "q5_choice", "q6_choice", "q7_text", "user_agent", "id",
];

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

function Answer({ label, choice, text }: { label: string; choice?: string | null; text?: string | null }) {
  return (
    <div>
      <p className="font-mono text-xs text-gray-500 uppercase">{label}</p>
      {choice && <p className="text-gray-900">{choice}</p>}
      {text ? (
        <p className="mt-1 whitespace-pre-wrap text-gray-900 bg-amber-50 border border-amber-100 rounded px-3 py-2">{text}</p>
      ) : !choice ? (
        <p className="text-gray-400">(blank)</p>
      ) : null}
    </div>
  );
}

export default function ProveTable({ responses }: { responses: SurveyResponse[] }) {
  const [tier, setTier] = useState("");
  const [hood, setHood] = useState("");
  const [contactedFilter, setContactedFilter] = useState("");
  const [expanded, setExpanded] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  // Optimistic contacted flags so the toggle feels instant.
  const [overrides, setOverrides] = useState<Record<string, boolean>>({});

  const hoods = useMemo(
    () => Array.from(new Set(responses.map((r) => r.neighborhood))).sort(),
    [responses]
  );

  const rows = useMemo(
    () =>
      responses.filter((r) => {
        const isContacted = overrides[r.id] ?? r.contacted;
        if (tier && r.tier !== tier) return false;
        if (hood && r.neighborhood !== hood) return false;
        if (contactedFilter === "yes" && !isContacted) return false;
        if (contactedFilter === "no" && isContacted) return false;
        return true;
      }),
    [responses, tier, hood, contactedFilter, overrides]
  );

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
    const lines = [CSV_COLUMNS.join(",")].concat(
      responses.map((r) =>
        CSV_COLUMNS.map((c) => csvCell(c === "contacted" ? overrides[r.id] ?? r.contacted : r[c])).join(",")
      )
    );
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
        <select value={tier} onChange={(e) => setTier(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">All tiers</option>
          {TIERS.map((t) => <option key={t} value={t}>{t}</option>)}
        </select>
        <select value={hood} onChange={(e) => setHood(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">All neighborhoods</option>
          {hoods.map((h) => <option key={h} value={h}>{h}</option>)}
        </select>
        <select value={contactedFilter} onChange={(e) => setContactedFilter(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">Contacted: any</option>
          <option value="no">Not yet contacted</option>
          <option value="yes">Contacted</option>
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
              <th className="text-left px-3 py-3 font-medium text-gray-500">Email</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Neighborhood</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Score</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Tier</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Src</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">SMS</th>
              <th className="text-left px-3 py-3 font-medium text-gray-500">Contacted</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {rows.map((r) => {
              const open = expanded === r.id;
              const isContacted = overrides[r.id] ?? r.contacted;
              return (
                <RowGroup key={r.id} open={open}>
                  <tr className="hover:bg-gray-50 cursor-pointer" onClick={() => setExpanded(open ? null : r.id)}>
                    <td className="pl-3 text-gray-400">{open ? <ChevronDown size={16} /> : <ChevronRight size={16} />}</td>
                    <td className="px-3 py-3 text-gray-500 whitespace-nowrap">{new Date(r.created_at).toLocaleString()}</td>
                    <td className="px-3 py-3 font-medium">{r.email}</td>
                    <td className="px-3 py-3 text-gray-600 whitespace-nowrap">{r.neighborhood}</td>
                    <td className="px-3 py-3 font-mono">{r.score}/14</td>
                    <td className="px-3 py-3"><span className={`inline-block rounded px-2 py-0.5 text-xs font-semibold ${tierClass(r.tier)}`}>{r.tier}</span></td>
                    <td className="px-3 py-3 font-mono text-xs text-gray-500">{r.src}</td>
                    <td className="px-3 py-3 text-gray-500">{r.sms_consent ? "yes" : r.phone ? "no" : "no phone"}</td>
                    <td className="px-3 py-3" onClick={(e) => e.stopPropagation()}>
                      <button
                        onClick={() => toggle(r)}
                        disabled={busy === r.id}
                        className={`rounded-md px-2.5 py-1 text-xs font-medium border ${isContacted ? "bg-green-50 border-green-300 text-green-800" : "bg-white border-gray-300 text-gray-600 hover:bg-gray-50"}`}
                      >
                        {isContacted ? "Contacted" : "Mark contacted"}
                      </button>
                    </td>
                  </tr>
                  {open && (
                    <tr className="bg-gray-50">
                      <td></td>
                      <td colSpan={8} className="px-3 py-4">
                        <div className="grid md:grid-cols-2 gap-4 text-sm">
                          <Answer label="Q1 · When you say the city, you mean" choice={r.q1_choice} text={r.q1_text} />
                          <Answer label="Q2 · Does that change where you stand on Earth" choice={r.q2_choice} text={r.q2_text} />
                          <Answer label="Q3 · Green MetroCard" choice={r.q3_choice} />
                          <Answer label="Q4 · Washington Square Park" choice={r.q4_choice} />
                          <Answer label="Q5 · Before the MetroCard" choice={r.q5_choice} />
                          <Answer label="Q6 · It's brick outside" choice={r.q6_choice} />
                          <Answer label="Q7 · New Jersey." text={r.q7_text} />
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
                </RowGroup>
              );
            })}
          </tbody>
        </table>
      )}
    </div>
  );
}

/** Lets a row and its expansion share one key without an extra DOM wrapper. */
function RowGroup({ children }: { children: React.ReactNode; open: boolean }) {
  return <>{children}</>;
}
