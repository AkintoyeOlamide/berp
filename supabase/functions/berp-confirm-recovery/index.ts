// Confirms a 4-digit BERP recovery code and sets a new password.
// Deploy:
//   npx supabase functions deploy berp-confirm-recovery --project-ref vfrgawklszvhddrvjjxj

import { createClient } from 'npm:@supabase/supabase-js@2'

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
    const body = await req.json()
    const email = String(body.email ?? '')
      .trim()
      .toLowerCase()
    const code = String(body.code ?? '').trim()
    const password = String(body.password ?? '')

    if (!email.includes('@') || !/^\d{4}$/.test(code)) {
      return json({ error: 'Enter the 4-digit code from your email.' }, 400)
    }
    if (password.length < 6) {
      return json({ error: 'Password must be at least 6 characters.' }, 400)
    }

    const url = Deno.env.get('SUPABASE_URL')!
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const admin = createClient(url, serviceKey)

    const { data: row, error: rowError } = await admin
      .from('berp_recovery_codes')
      .select('code_hash, expires_at, attempts')
      .eq('email', email)
      .maybeSingle()

    if (rowError) throw rowError
    if (!row) {
      return json({ error: 'Invalid or expired code.' }, 400)
    }
    if (new Date(row.expires_at).getTime() < Date.now()) {
      await admin.from('berp_recovery_codes').delete().eq('email', email)
      return json({ error: 'That code has expired. Request a new one.' }, 400)
    }
    if ((row.attempts ?? 0) >= 5) {
      await admin.from('berp_recovery_codes').delete().eq('email', email)
      return json({ error: 'Too many attempts. Request a new code.' }, 400)
    }

    const expected = await sha256(`${email}:${code}`)
    if (expected !== row.code_hash) {
      await admin
        .from('berp_recovery_codes')
        .update({ attempts: (row.attempts ?? 0) + 1 })
        .eq('email', email)
      return json({ error: 'Incorrect code. Try again.' }, 400)
    }

    const userId = await findUserId(admin, email)
    if (!userId) {
      return json({ error: 'Invalid or expired code.' }, 400)
    }

    const { error: updateError } = await admin.auth.admin.updateUserById(
      userId,
      { password },
    )
    if (updateError) throw updateError

    await admin.from('berp_recovery_codes').delete().eq('email', email)

    return json({ ok: true })
  } catch (error) {
    console.error(error)
    return json({ error: 'Could not reset password. Try again.' }, 500)
  }
})
