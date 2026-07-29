"use client";

import { useState } from "react";
import { Database, AlertTriangle, CheckCircle, XCircle } from "lucide-react";
import { runSeedMock, runSeedReplies } from "./actions";

type Status = "idle" | "confirming" | "running" | "success" | "error";

export default function SeedPage() {
  const [status, setStatus] = useState<Status>("idle");
  const [log, setLog] = useState<string[]>([]);

  async function handleSeed() {
    if (status === "idle") {
      setStatus("confirming");
      return;
    }

    if (status !== "confirming") return;

    setStatus("running");
    setLog([]);

    setLog((prev) => [...prev, "Running seed_mock.sql..."]);
    const mockResult = await runSeedMock();
    if (!mockResult.success) {
      setLog((prev) => [...prev, `seed_mock.sql failed: ${mockResult.error}`]);
      setStatus("error");
      return;
    }
    setLog((prev) => [...prev, "seed_mock.sql completed."]);

    setLog((prev) => [...prev, "Running seed_replies.sql..."]);
    const repliesResult = await runSeedReplies();
    if (!repliesResult.success) {
      setLog((prev) => [
        ...prev,
        `seed_replies.sql failed: ${repliesResult.error}`,
      ]);
      setStatus("error");
      return;
    }
    setLog((prev) => [...prev, "seed_replies.sql completed."]);

    setLog((prev) => [...prev, "All seeds completed successfully."]);
    setStatus("success");
  }

  function handleReset() {
    setStatus("idle");
    setLog([]);
  }

  return (
    <div>
      <h2 className="text-2xl font-bold mb-6">Database Seeding</h2>

      <div className="max-w-lg">
        <div className="bg-white rounded-lg border border-gray-200 p-6">
          <div className="flex items-start gap-3 mb-4">
            <Database size={20} className="text-gray-500 mt-0.5" />
            <div>
              <h3 className="font-semibold">Seed Mock Data</h3>
              <p className="text-sm text-gray-500 mt-1">
                Runs <code className="text-xs bg-gray-100 px-1 py-0.5 rounded">seed_mock.sql</code> and{" "}
                <code className="text-xs bg-gray-100 px-1 py-0.5 rounded">seed_replies.sql</code> against
                the database. This will clean existing mock data (UUIDs starting with b/c/d/e/f) and re-seed.
              </p>
            </div>
          </div>

          {status === "confirming" && (
            <div className="bg-yellow-50 border border-yellow-200 rounded-md p-3 mb-4 flex items-start gap-2">
              <AlertTriangle size={16} className="text-yellow-600 mt-0.5 shrink-0" />
              <p className="text-sm text-yellow-800">
                This will delete and re-insert mock data. Are you sure?
              </p>
            </div>
          )}

          <div className="flex gap-2">
            {(status === "idle" || status === "confirming") && (
              <button
                onClick={handleSeed}
                className={`px-4 py-2 text-sm font-medium rounded-md transition-colors ${
                  status === "confirming"
                    ? "bg-yellow-500 text-white hover:bg-yellow-600"
                    : "bg-gray-900 text-white hover:bg-gray-700"
                }`}
              >
                {status === "confirming" ? "Confirm Seed" : "Seed Database"}
              </button>
            )}
            {status === "confirming" && (
              <button
                onClick={handleReset}
                className="px-4 py-2 text-sm font-medium rounded-md bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
              >
                Cancel
              </button>
            )}
            {status === "running" && (
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <div className="animate-spin h-4 w-4 border-2 border-gray-300 border-t-gray-600 rounded-full" />
                Running...
              </div>
            )}
            {(status === "success" || status === "error") && (
              <button
                onClick={handleReset}
                className="px-4 py-2 text-sm font-medium rounded-md bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors"
              >
                Reset
              </button>
            )}
          </div>
        </div>

        {log.length > 0 && (
          <div className="mt-4 bg-gray-900 rounded-lg p-4">
            {log.map((line, i) => (
              <div key={i} className="flex items-start gap-2 text-sm font-mono">
                {line.includes("failed") ? (
                  <XCircle size={14} className="text-red-400 mt-0.5 shrink-0" />
                ) : line.includes("completed") || line.includes("successfully") ? (
                  <CheckCircle size={14} className="text-green-400 mt-0.5 shrink-0" />
                ) : (
                  <span className="text-gray-500 shrink-0">$</span>
                )}
                <span className={line.includes("failed") ? "text-red-400" : "text-gray-300"}>
                  {line}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
