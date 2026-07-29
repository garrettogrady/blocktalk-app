"use server";

import { Client } from "pg";
import seedMockSql from "../../sql/seed_mock.sql";
import seedRepliesSql from "../../sql/seed_replies.sql";
import seedReportsSql from "../../sql/seed_reports.sql";

async function executeSql(sql: string): Promise<{ success: boolean; error?: string }> {
  const dbUrl = process.env.SUPABASE_DB_URL;
  if (!dbUrl) {
    return { success: false, error: "SUPABASE_DB_URL not configured" };
  }

  const client = new Client({ connectionString: dbUrl });

  try {
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
  return executeSql(seedMockSql);
}

export async function runSeedReplies() {
  return executeSql(seedRepliesSql);
}

export async function runSeedReports() {
  return executeSql(seedReportsSql);
}
