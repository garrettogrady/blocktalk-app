"use client";

import { useState } from "react";
import { generateBatch, revokeCode } from "./actions";
import { Copy, Trash2, Download } from "lucide-react";

type InviteCode = {
  code: string;
  redeemed_by: string | null;
  redeemed_at: string | null;
  created_at: string;
  created_by: string | null;
};

export default function InviteTable({ codes: initial }: { codes: InviteCode[] }) {
  const [codes, setCodes] = useState(initial);
  const [batchSize, setBatchSize] = useState(10);
  const [generating, setGenerating] = useState(false);
  const [copied, setCopied] = useState<string | null>(null);

  async function handleGenerate() {
    setGenerating(true);
    const result = await generateBatch(batchSize);
    if (result.codes) {
      window.location.reload();
    }
    setGenerating(false);
  }

  async function handleRevoke(code: string) {
    if (!confirm(`Revoke code ${code}?`)) return;
    await revokeCode(code);
    setCodes(codes.filter((c) => c.code !== code));
  }

  function handleCopy(code: string) {
    navigator.clipboard.writeText(code);
    setCopied(code);
    setTimeout(() => setCopied(null), 1500);
  }

  function handleExportCSV() {
    const header = "code,status,redeemed_at,created_at,created_by";
    const rows = codes.map((c) => {
      const status = c.redeemed_by ? "used" : "available";
      return `${c.code},${status},${c.redeemed_at ?? ""},${c.created_at},${c.created_by ?? "admin"}`;
    });
    const csv = [header, ...rows].join("\n");
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `invite-codes-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  const available = codes.filter((c) => !c.redeemed_by);
  const used = codes.filter((c) => c.redeemed_by);

  return (
    <div className="space-y-6">
      {/* Generate controls */}
      <div className="flex items-center gap-3">
        <label className="text-sm font-medium text-gray-700">Generate</label>
        <input
          type="number"
          min={1}
          max={500}
          value={batchSize}
          onChange={(e) => setBatchSize(Number(e.target.value))}
          className="w-20 px-2 py-1.5 text-sm border border-gray-300 rounded-md"
        />
        <span className="text-sm text-gray-500">codes</span>
        <button
          onClick={handleGenerate}
          disabled={generating}
          className="px-4 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 disabled:opacity-50"
        >
          {generating ? "Generating..." : "Generate"}
        </button>
        <div className="flex-1" />
        <button
          onClick={handleExportCSV}
          className="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200"
        >
          <Download size={14} />
          Export CSV
        </button>
      </div>

      {/* Stats */}
      <div className="flex gap-4 text-sm">
        <span className="px-3 py-1 bg-green-50 text-green-700 rounded-full font-medium">
          {available.length} available
        </span>
        <span className="px-3 py-1 bg-gray-100 text-gray-600 rounded-full font-medium">
          {used.length} used
        </span>
        <span className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full font-medium">
          {codes.length} total
        </span>
      </div>

      {/* Table */}
      <div className="overflow-hidden border border-gray-200 rounded-lg">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Code</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created</th>
              <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Source</th>
              <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200 bg-white">
            {codes.map((c) => (
              <tr key={c.code} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-mono text-sm font-semibold tracking-wider">
                  {c.code}
                </td>
                <td className="px-4 py-3 text-sm">
                  {c.redeemed_by ? (
                    <span className="px-2 py-0.5 text-xs font-medium bg-gray-100 text-gray-600 rounded">
                      Used {c.redeemed_at ? new Date(c.redeemed_at).toLocaleDateString("en-US") : ""}
                    </span>
                  ) : (
                    <span className="px-2 py-0.5 text-xs font-medium bg-green-50 text-green-700 rounded">
                      Available
                    </span>
                  )}
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {new Date(c.created_at).toLocaleDateString("en-US")}
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {c.created_by ? "User" : "Admin"}
                </td>
                <td className="px-4 py-3 text-right">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      onClick={() => handleCopy(c.code)}
                      className="p-1 text-gray-400 hover:text-gray-600"
                      title="Copy code"
                    >
                      {copied === c.code ? (
                        <span className="text-xs text-green-600 font-medium">Copied</span>
                      ) : (
                        <Copy size={14} />
                      )}
                    </button>
                    {!c.redeemed_by && (
                      <button
                        onClick={() => handleRevoke(c.code)}
                        className="p-1 text-gray-400 hover:text-red-500"
                        title="Revoke code"
                      >
                        <Trash2 size={14} />
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
