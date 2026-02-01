// supabase/functions/send-push-notification/index.ts
// Sends FCM V1 push notifications to a user's registered devices.
//
// Expects JSON body: { user_id, title, body, data? }
// Requires secrets: FIREBASE_SERVICE_ACCOUNT (full JSON key)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = "cleanslate-a4586";
const FCM_URL = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
const SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"];

// ── JWT helpers (no external lib needed) ──────────────────────────

function base64url(buf: ArrayBuffer): string {
  return btoa(String.fromCharCode(...new Uint8Array(buf)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    binary.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
}

async function getAccessToken(
  clientEmail: string,
  privateKey: string
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(
    new TextEncoder().encode(JSON.stringify({ alg: "RS256", typ: "JWT" }))
  );
  const payload = base64url(
    new TextEncoder().encode(
      JSON.stringify({
        iss: clientEmail,
        sub: clientEmail,
        aud: "https://oauth2.googleapis.com/token",
        iat: now,
        exp: now + 3600,
        scope: SCOPES.join(" "),
      })
    )
  );

  const key = await importPrivateKey(privateKey);
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${payload}`)
  );

  const jwt = `${header}.${payload}.${base64url(sig)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Token exchange failed: ${text}`);
  }

  const { access_token } = await res.json();
  return access_token;
}

// ── Main handler ──────────────────────────────────────────────────

serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };

  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { user_id, title, body, data } = await req.json();

    if (!user_id || !title) {
      return new Response(
        JSON.stringify({ error: "Missing user_id or title" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Get FCM tokens ────────────────────────────────────────────

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: tokens, error } = await supabase
      .from("user_fcm_tokens")
      .select("fcm_token")
      .eq("user_id", user_id);

    if (error || !tokens?.length) {
      return new Response(
        JSON.stringify({ success: true, sent: 0, reason: "no_tokens" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Authenticate with FCM V1 ─────────────────────────────────

    const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
    const accessToken = await getAccessToken(sa.client_email, sa.private_key);

    // ── Send to each device ──────────────────────────────────────

    const staleTokens: string[] = [];
    let successCount = 0;

    await Promise.all(
      tokens.map(async ({ fcm_token }: { fcm_token: string }) => {
        const res = await fetch(FCM_URL, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: fcm_token,
              notification: { title, body: body || "" },
              data: data || {},
              android: {
                priority: "high",
                notification: {
                  channel_id: "cleanslate_notifications",
                  priority: "HIGH",
                  default_vibrate_timings: true,
                  default_sound: true,
                },
              },
              apns: {
                payload: {
                  aps: {
                    alert: { title, body: body || "" },
                    sound: "default",
                    badge: 1,
                  },
                },
              },
            },
          }),
        });

        if (res.ok) {
          successCount++;
        } else {
          const errBody = await res.text();
          // Token is stale / unregistered — mark for cleanup
          if (
            res.status === 404 ||
            errBody.includes("UNREGISTERED") ||
            errBody.includes("NOT_FOUND")
          ) {
            staleTokens.push(fcm_token);
          }
          console.error(`FCM send failed for token: ${res.status} ${errBody}`);
        }
      })
    );

    // ── Clean up stale tokens ────────────────────────────────────

    if (staleTokens.length > 0) {
      await supabase
        .from("user_fcm_tokens")
        .delete()
        .in_("fcm_token", staleTokens);
      console.log(`Cleaned up ${staleTokens.length} stale FCM tokens`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: successCount,
        total: tokens.length,
        cleaned: staleTokens.length,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Push notification error:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
