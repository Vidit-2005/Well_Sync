import { createClient } from "@supabase/supabase-js";
import { importPKCS8, SignJWT } from "jose";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type PushRequest = {
  patientId: string;
  title: string;
  body: string;
  kind?: string;
};

type DeviceTokenRow = {
  token: string;
};

function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`Missing env: ${name}`);
  return value;
}

async function buildApnsJWT() {
  const keyID = requiredEnv("APNS_KEY_ID");
  const teamID = requiredEnv("APNS_TEAM_ID");
  const privateKey = requiredEnv("APNS_PRIVATE_KEY");

  const key = await importPKCS8(privateKey, "ES256");

  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyID })
    .setIssuedAt()
    .setIssuer(teamID)
    .sign(key);
}

async function sendToAPNS(deviceToken: string, title: string, body: string) {
  const jwt = await buildApnsJWT();
  const topic = requiredEnv("APNS_BUNDLE_ID");
  const useSandbox = (Deno.env.get("APNS_USE_SANDBOX") ?? "true").toLowerCase() === "true";
  const host = useSandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com";

  const payload = {
    aps: {
      alert: { title, body },
      sound: "default",
    },
  };

  const response = await fetch(`https://${host}/3/device/${deviceToken}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": topic,
      "apns-push-type": "alert",
      "apns-priority": "10",
      "content-type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const bodyText = await response.text();
  return { ok: response.ok, status: response.status, bodyText };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseURL = requiredEnv("SUPABASE_URL");
    const serviceRole = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");

    const supabase = createClient(supabaseURL, serviceRole);

    const { patientId, title, body } = (await req.json()) as PushRequest;
    if (!patientId || !title || !body) {
      return new Response(
        JSON.stringify({ error: "Missing patientId/title/body" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data, error } = await supabase
      .from("device_push_tokens")
      .select("token")
      .eq("patient_id", patientId)
      .eq("platform", "ios")
      .eq("is_active", true);

    if (error) throw error;

    const tokens = (data ?? []) as DeviceTokenRow[];
    if (!tokens.length) {
      return new Response(
        JSON.stringify({ success: true, sent: 0, reason: "No active patient tokens" }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const results = [];
    for (const row of tokens) {
      const result = await sendToAPNS(row.token, title, body);
      results.push({ token: row.token, ...result });

      if (!result.ok && [400, 410].includes(result.status)) {
        await supabase
          .from("device_push_tokens")
          .update({ is_active: false })
          .eq("token", row.token);
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent: results.filter((r) => r.ok).length,
        total: results.length,
        results,
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
