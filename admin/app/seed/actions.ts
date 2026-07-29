"use server";

import { Client } from "pg";
import { readFileSync } from "fs";
import { join } from "path";

async function executeSqlFile(filename: string): Promise<{ success: boolean; error?: string }> {
  const dbUrl = process.env.SUPABASE_DB_URL;
  if (!dbUrl) {
    return { success: false, error: "SUPABASE_DB_URL not configured" };
  }

  const client = new Client({ connectionString: dbUrl });

  try {
    const filePath = join(process.cwd(), "..", "scripts", filename);
    const sql = readFileSync(filePath, "utf-8");

    await client.connect();
    await client.query(sql);
    await client.end();

    return { success: true };
  } catch (err: any) {
    try { await client.end(); } catch {}
    return { success: false, error: err.message };
  }
}

export async function runSeedMock() {
  return executeSqlFile("seed_mock.sql");
}

export async function runSeedReplies() {
  return executeSqlFile("seed_replies.sql");
}

export async function runSeedReports() {
  return executeSqlFile("seed_reports.sql");
}
