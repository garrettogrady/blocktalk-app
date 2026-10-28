"use client";

import { useMemo, useState } from "react";
import { Download } from "lucide-react";
import { setRantContacted } from "./actions";
import type { RantResponse } from "@/lib/types";

const TABS: Record<string, string> = { who: "Who do you think you are", ai: "AI this and AI that", influencers: "Fuck influencers" };

function csvCell(v: unknown): string {
  if (v === null || v === undefined) return "";
  const s = String(v);
  return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

export default function RantTable({ rants }: { rants: RantResponse[] }) {
  const [tab, setTab] = useState("");
  const [withEmail, setWithEmail] = useState("");
  const [busy, setBusy] = useState<string | null>(null);
  const [overrides, setOverrides] = useState<Record<string, boolean>>({});

  const rows = useMemo(() => rants.filter((r) => {
    if (tab && r.tab !== tab) return false;
    if (withEmail === "yes" && !r.email) return false;
    if (withEmail === "no" && r.email) return false;
    return true;
  }), [rants, tab, withEmail]);

  async function toggle(r: RantResponse) {
    const next = !(overrides[r.id] ?? r.contacted);
    setBusy(r.id);
    setOverrides((o) => ({ ...o, [r.id]: next }));
    const result = await setRantContacted(r.id, next);
    if ("error" in result && result.error) {
      setOverrides((o) => ({ ...o, [r.id]: !next }));
      alert(`Error: ${result.error}`);
    }
    setBusy(null);
  }

  function exportCsv() {
    const header = ["created_at", "tab", "email", "contacted", "body", "user_agent", "id"];
    const lines = [header.join(",")].concat(rants.map((r) =>
      [r.created_at, r.tab, r.email, overrides[r.id] ?? r.contacted, r.body, r.user_agent, r.id].map(csvCell).join(",")));
    const blob = new Blob(["﻿" + lines.join("\n")], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `rant-takes-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
      <div className="flex flex-wrap items-center gap-3 px-4 py-3 border-b border-gray-200 bg-gray-50">
        <select value={tab} onChange={(e) => setTab(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">All tabs</option>
          {Object.entries(TABS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
        </select>
        <select value={withEmail} onChange={(e) => setWithEmail(e.target.value)} className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white">
          <option value="">Email: any</option><option value="yes">Left an email</option><option value="no">No email</option>
        </select>
        <span className="text-sm text-gray-500">{rows.length} shown</span>
        <button onClick={exportCsv} className="ml-auto inline-flex items-center gap-2 text-sm font-medium text-gray-700 border border-gray-300 rounded-md px-3 py-1.5 bg-white hover:bg-gray-50">
          <Download size={14} /> Export CSV (all {rants.length})
        </button>
      </div>
      {rows.length === 0 ? (
        <div className="p-8 text-center text-gray-500">No takes yet.</div>
      ) : (
        <ul className="divide-y divide-gray-100">
          {rows.map((r) => {
            const isContacted = overrides[r.id] ?? r.contacted;
            return (
              <li key={r.id} className="px-4 py-3">
                <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-gray-500 font-mono">
                  <span>{new Date(r.created_at).toLocaleString("en-US")}</span>
                  <span className="uppercase">{TABS[r.tab] ?? r.tab}</span>
                  <span className={r.email ? "text-gray-900 font-semibold" : ""}>{r.email ?? "no email"}</span>
                  <button onClick={() => toggle(r)} disabled={busy === r.id}
                    className={`ml-auto rounded-md px-2.5 py-1 text-xs font-medium border font-sans ${isContacted ? "bg-green-50 border-green-300 text-green-800" : "bg-white border-gray-300 text-gray-600 hover:bg-gray-50"}`}>
                    {isContacted ? "Contacted" : "Mark contacted"}
                  </button>
                </div>
                <p className="mt-2 whitespace-pre-wrap text-gray-900 bg-amber-50 border border-amber-100 rounded px-3 py-2 text-sm">{r.body}</p>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
