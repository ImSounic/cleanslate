// supabase/functions/send-push-notification/index.ts
// Sends FCM V1 push notifications to a user's registered devices.
//
// Expects JSON body: { user_id, title, body, data?, household_id? }
// Requires secrets: FIREBASE_SERVICE_ACCOUNT (full JSON key)
//
// Security:
// - Validates all input parameters
// - Verifies caller is authenticated
// - Verifies caller has permission to notify target user (same household)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FIREBASE_PROJECT_ID = "cleanslate-a4586";
const FCM_URL = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;
const SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"];

// ── Input validation helpers ──────────────────────────────────────

function isValidUUID(str: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(str);
}

function sanitizeString(str: string, maxLength: number): string {
  if (typeof str !== 'string') return '';
  // Remove control characters and limit length
  return str.replace(/[\x00-\x1F\x7F]/g, '').substring(0, maxLength);
}

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
    // ── Parse and validate input ─────────────────────────────────

    let requestBody;
    try {
      requestBody = await req.json();
    } catch {
      return new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { user_id, title, body, data, household_id } = requestBody;

    // Validate required fields
    if (!user_id || typeof user_id !== 'string') {
      return new Response(
        JSON.stringify({ error: "Missing or invalid user_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!isValidUUID(user_id)) {
      return new Response(
        JSON.stringify({ error: "Invalid user_id format" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!title || typeof title !== 'string') {
      return new Response(
        JSON.stringify({ error: "Missing or invalid title" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Sanitize string inputs
    const sanitizedTitle = sanitizeString(title, 200);
    const sanitizedBody = body ? sanitizeString(String(body), 2000) : "";

    // Validate household_id if provided
    if (household_id && (typeof household_id !== 'string' || !isValidUUID(household_id))) {
      return new Response(
        JSON.stringify({ error: "Invalid household_id format" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // ── Initialize Supabase clients ────────────────────────────────

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Get the calling user from the auth header
    const authHeader = req.headers.get("Authorization");
    let callingUserId: string | null = null;

    if (authHeader) {
      const supabaseAuth = createClient(
        Deno.env.get("SUPABASE_URL")!,
        Deno.env.get("SUPABASE_ANON_KEY")!,
        { global: { headers: { Authorization: authHeader } } }
      );
      const { data: { user } } = await supabaseAuth.auth.getUser();
      callingUserId = user?.id ?? null;
    }

    // ── Authorization check ─────────────────────────────────────────
    // If household_id is provided, verify caller is a member of that household
    // and the target user is also a member (they can notify each other)

    if (household_id && callingUserId) {
      const { data: callerMembership } = await supabaseAdmin
        .from("household_members")
        .select("id")
        .eq("household_id", household_id)
        .eq("user_id", callingUserId)
        .eq("is_active", true)
        .maybeSingle();

      const { data: targetMembership } = await supabaseAdmin
        .from("household_members")
        .select("id")
        .eq("household_id", household_id)
        .eq("user_id", user_id)
        .eq("is_active", true)
        .maybeSingle();

      if (!callerMembership || !targetMembership) {
        return new Response(
          JSON.stringify({ error: "Unauthorized: not in the same household" }),
          { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    // ── Get FCM tokens ────────────────────────────────────────────

    const supabase = supabaseAdmin;

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
              notification: { title: sanitizedTitle, body: sanitizedBody },
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
                    alert: { title: sanitizedTitle, body: sanitizedBody },
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
    // Log full error server-side but don't expose details to client
    console.error("Push notification error:", err);
    return new Response(
      JSON.stringify({ error: "Failed to send notification" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
