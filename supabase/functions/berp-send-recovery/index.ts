// Sends a 4-digit BERP recovery code via Gmail SMTP (same as vops-send-recovery).
// Deploy:
//   npx supabase functions deploy berp-send-recovery --project-ref vfrgawklszvhddrvjjxj
// Secrets (shared with vops if already set):
//   SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASS EMAIL_FROM

import { createClient } from 'npm:@supabase/supabase-js@2'
import nodemailer from 'npm:nodemailer@6'

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, 'Content-Type': 'application/json' },
  })
}

async function sha256(value: string) {
  const data = new TextEncoder().encode(value)
  const digest = await crypto.subtle.digest('SHA-256', data)
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

async function findUserId(
  admin: ReturnType<typeof createClient>,
  email: string,
) {
  const { data: profile } = await admin
    .from('profiles')
    .select('id')
    .ilike('email', email)
    .maybeSingle()
  if (profile?.id) return profile.id as string

  const { data } = await admin.auth.admin.listUsers({ page: 1, perPage: 1000 })
  const match = (data?.users ?? []).find(
    (user) => (user.email ?? '').trim().toLowerCase() === email,
  )
  return match?.id ?? null
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: cors })
  }

  try {
    const { email: rawEmail } = await req.json()
    const email = String(rawEmail ?? '')
      .trim()
      .toLowerCase()
    if (!email || !email.includes('@')) {
      return json({ error: 'Enter a valid email.' }, 400)
    }

    const url = Deno.env.get('SUPABASE_URL')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const admin = createClient(url, serviceKey)

    const userId = await findUserId(admin, email)
    if (!userId) {
      return json({
        ok: true,
        message: 'If that email is registered, a code was sent.',
      })
    }

    const code = String(Math.floor(Math.random() * 10000)).padStart(4, '0')
    const codeHash = await sha256(`${email}:${code}`)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString()

    const { error: upsertError } = await admin.from('berp_recovery_codes').upsert({
      email,
      code_hash: codeHash,
      expires_at: expiresAt,
      attempts: 0,
      created_at: new Date().toISOString(),
    })
    if (upsertError) throw upsertError

    const host = Deno.env.get('SMTP_HOST')
    const port = Number(Deno.env.get('SMTP_PORT') ?? '587')
    const secureEnv = Deno.env.get('SMTP_SECURE')
    const userName = Deno.env.get('SMTP_USER')
    const pass = Deno.env.get('SMTP_PASS')
    const from =
      Deno.env.get('SMTP_FROM') ??
      Deno.env.get('EMAIL_FROM') ??
      userName
    const secure =
      secureEnv != null
        ? !['false', '0', 'no'].includes(secureEnv.toLowerCase())
        : port === 465

    if (!host || !userName || !pass || !from) {
      console.error('Missing SMTP secrets')
      return json(
        { error: 'Recovery email is not configured. Set SMTP_* secrets.' },
        500,
      )
    }

    const transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: { user: userName, pass },
    })

    await transporter.sendMail({
      from,
      to: email,
      subject: `BERP recovery code: ${code}`,
      text: `Your BERP password recovery code is ${code}.\n\nIt expires in 10 minutes.\nIf you did not request this, ignore this email.`,
      html: `<p>Your <strong>BERP</strong> password recovery code is:</p>
        <p style="font-size:28px;letter-spacing:8px;font-weight:700">${code}</p>
        <p>It expires in 10 minutes.</p>`,
    })

    return json({
      ok: true,
      message: 'If that email is registered, a code was sent.',
    })
  } catch (error) {
    console.error(error)
    return json({ error: 'Could not send recovery code. Try again.' }, 500)
  }
})
