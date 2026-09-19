import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

async function sendCodeEmail(to: string, code: string) {
  const resendKey = Deno.env.get("RESEND_API_KEY") ?? "";
  const from =
    Deno.env.get("RESET_FROM_EMAIL") ?? "BERP <noreply@vmoaeros.com>";
  if (!resendKey) return false;

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from,
      to,
      subject: "Your BERP password reset code",
      html:
        `<p>Your BERP reset code is <strong style="font-size:22px;letter-spacing:4px;">${code}</strong>.</p>` +
        `<p>It expires in 15 minutes. If you did not request this, ignore this email.</p>`,
    }),
  });
  return res.ok;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }

  try {
    const { email } = await req.json();
    const normalized = String(email ?? "").trim().toLowerCase();
    if (!normalized.includes("@")) {
      return json({ ok: false, error: "Enter a valid email address." }, 400);
    }

    const admin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data, error } = await admin.rpc("request_berp_password_reset", {
      p_email: normalized,
    });
    if (error) {
      return json({ ok: false, error: error.message }, 400);
    }

    const row = (data ?? {}) as {
      emailed?: boolean;
      reason?: string;
      code?: string;
    };

    if (row.emailed === true || row.reason === "no_user") {
      return json({ ok: true });
    }

    if (row.code) {
      const sent = await sendCodeEmail(normalized, row.code);
      if (sent) return json({ ok: true });
    }

    return json(
      { ok: false, error: "Could not send a reset code." },
      502,
    );
  } catch (error) {
    return json(
      { ok: false, error: error instanceof Error ? error.message : "Failed." },
      500,
    );
  }
});
