import { cookies } from 'next/headers'

const ADMIN_ID = 'cshoon950'
const ADMIN_PW = 'tngnsl421!'

export async function POST(request: Request) {
  const { id, password } = await request.json()

  if (id === ADMIN_ID && password === ADMIN_PW) {
    const cookieStore = await cookies()
    cookieStore.set('admin_session', 'authenticated', {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
      maxAge: 60 * 60 * 24 * 7, // 7 days
    })
    return Response.json({ ok: true })
  }

  return Response.json({ error: 'Invalid credentials' }, { status: 401 })
}
