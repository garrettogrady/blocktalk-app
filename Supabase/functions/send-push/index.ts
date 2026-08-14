// Supabase Edge Function: send-push
// Polls notification_queue for pending items and delivers via APNs HTTP/2.
// Deploy: supabase functions deploy send-push
// Schedule: pg_cron or Supabase scheduled function every 1-2 minutes.
//
// Required secrets:
//   APNS_KEY_ID      — Apple push key ID
//   APNS_TEAM_ID     — Apple team ID
//   APNS_AUTH_KEY     — .p8 key contents (base64 or raw PEM)
//   APNS_BUNDLE_ID   — com.blocktalk.nyc

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DAILY_CAP = 8;
const BATCH_SIZE = 50;

interface QueueItem {
  id: string;
  user_id: string;
  post_id: string | null;
  kind: string;
  title: string;
  body: string;
  status: string;
  send_after: string;
  attempt_count: number;
}

interface DeviceToken {
  token: string;
  sandbox: boolean;
}

// --- APNs JWT Auth ---

async function importPKCS8Key(pem: string): Promise<CryptoKey> {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    binary,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );
}

function base64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function makeJWT(
  keyId: string,
  teamId: string,
  privateKey: CryptoKey
): Promise<string> {
  const header = base64url(
    new TextEncoder().encode(
      JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" })
    )
  );
  const now = Math.floor(Date.now() / 1000);
  const claims = base64url(
    new TextEncoder().encode(
      JSON.stringify({ iss: teamId, iat: now, exp: now + 3600 })
    )
  );
  const sigInput = new TextEncoder().encode(`${header}.${claims}`);
  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    privateKey,
    sigInput
  );
  // Convert DER signature to raw r||s (64 bytes)
  const derSig = new Uint8Array(sig);
  let r: Uint8Array, s: Uint8Array;
  if (derSig[0] === 0x30) {
    // DER encoded
    const rLen = derSig[3];
    const rStart = 4;
    r = derSig.slice(
      rStart + (rLen > 32 ? 1 : 0),
      rStart + rLen
    );
    const sLenIdx = rStart + rLen + 1;
    const sLen = derSig[sLenIdx];
    const sStart = sLenIdx + 1;
    s = derSig.slice(
      sStart + (sLen > 32 ? 1 : 0),
      sStart + sLen
    );
  } else {
    // Already raw
    r = derSig.slice(0, 32);
    s = derSig.slice(32, 64);
  }
  // Pad to 32 bytes each
  const padded = new Uint8Array(64);
  padded.set(r.length <= 32 ? r : r.slice(r.length - 32), 32 - Math.min(r.length, 32));
  padded.set(s.length <= 32 ? s : s.slice(s.length - 32), 64 - Math.min(s.length, 32));
  return `${header}.${claims}.${base64url(padded)}`;
}

// --- APNs Send ---

async function sendToAPNs(
  token: string,
  sandbox: boolean,
  payload: object,
  jwt: string,
  bundleId: string
): Promise<{ status: number; body: string }> {
  const host = sandbox
    ? "https://api.sandbox.push.apple.com"
    : "https://api.push.apple.com";
  const resp = await fetch(`${host}/3/device/${token}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": bundleId,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });
  const body = await resp.text();
  return { status: resp.status, body };
}

// --- Main Handler ---

Deno.serve(async () => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const authKeyPem = Deno.env.get("APNS_AUTH_KEY")!;
  const bundleId = Deno.env.get("APNS_BUNDLE_ID") || "com.blocktalk.nyc";

  const sb = createClient(supabaseUrl, serviceKey);

  // Import the APNs signing key and generate a JWT
  const privateKey = await importPKCS8Key(authKeyPem);
  const jwt = await makeJWT(keyId, teamId, privateKey);

  // Fetch pending notifications ready to send
  const { data: items, error: fetchErr } = await sb
    .from("notification_queue")
    .select("*")
    .eq("status", "pending")
    .lte("send_after", new Date().toISOString())
    .order("send_after", { ascending: true })
    .limit(BATCH_SIZE);

  if (fetchErr || !items || items.length === 0) {
    return new Response(
      JSON.stringify({ processed: 0, error: fetchErr?.message }),
      { headers: { "content-type": "application/json" } }
    );
  }

  // Track daily counts per user to enforce cap
  const dailyCounts: Record<string, number> = {};

  let sent = 0;
  let skipped = 0;
  let failed = 0;

  for (const item of items as QueueItem[]) {
    // Daily cap check
    if (!(item.user_id in dailyCounts)) {
      const { count } = await sb
        .from("notification_queue")
        .select("*", { count: "exact", head: true })
        .eq("user_id", item.user_id)
        .eq("status", "sent")
        .gte("processed_at", new Date(Date.now() - 86400000).toISOString());
      dailyCounts[item.user_id] = count || 0;
    }

    if (dailyCounts[item.user_id] >= DAILY_CAP) {
      await sb
        .from("notification_queue")
        .update({
          status: "skipped",
          last_error: "daily_cap_exceeded",
          processed_at: new Date().toISOString(),
        })
        .eq("id", item.id);
      skipped++;
      continue;
    }

    // Get device tokens for this user
    const { data: tokens } = await sb
      .from("device_tokens")
      .select("token, sandbox")
      .eq("user_id", item.user_id);

    if (!tokens || tokens.length === 0) {
      await sb
        .from("notification_queue")
        .update({
          status: "skipped",
          last_error: "no_device_tokens",
          processed_at: new Date().toISOString(),
        })
        .eq("id", item.id);
      skipped++;
      continue;
    }

    // Build APNs payload
    const payload = {
      aps: {
        alert: { title: item.title, body: item.body },
        sound: "default",
        "thread-id": item.post_id ? `post-${item.post_id}` : undefined,
      },
      post_id: item.post_id,
      kind: item.kind,
    };

    let anySent = false;
    for (const dt of tokens as DeviceToken[]) {
      const result = await sendToAPNs(dt.token, dt.sandbox, payload, jwt, bundleId);

      if (result.status === 200) {
        anySent = true;
      } else if (result.status === 410) {
        // Token is no longer valid — remove it
        await sb
          .from("device_tokens")
          .delete()
          .eq("user_id", item.user_id)
          .eq("token", dt.token);
      } else {
        console.error(
          `APNs error for ${item.id}: status=${result.status} body=${result.body}`
        );
      }
    }

    if (anySent) {
      await sb
        .from("notification_queue")
        .update({
          status: "sent",
          processed_at: new Date().toISOString(),
          attempt_count: item.attempt_count + 1,
        })
        .eq("id", item.id);
      dailyCounts[item.user_id] = (dailyCounts[item.user_id] || 0) + 1;
      sent++;
    } else {
      const attempts = item.attempt_count + 1;
      await sb
        .from("notification_queue")
        .update({
          status: attempts >= 3 ? "failed" : "pending",
          attempt_count: attempts,
          last_error: "all_tokens_failed",
          // Retry in 5 minutes
          send_after: new Date(Date.now() + 300000).toISOString(),
        })
        .eq("id", item.id);
      failed++;
    }
  }

  return new Response(
    JSON.stringify({ processed: items.length, sent, skipped, failed }),
    { headers: { "content-type": "application/json" } }
  );
});
