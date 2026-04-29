import { getAuthUsers, getProfiles, getAppEventsByUser, getErrorLogsByUser, getWorkspaces, getWorkspaceMembers, formatDate, formatDateTime } from '@/lib/queries'
import { UserActivityCharts } from './user-charts'
import Link from 'next/link'

export const dynamic = 'force-dynamic'

const SCREEN_COLORS = ['#6366f1', '#f59e0b', '#22c55e', '#ef4444', '#3b82f6', '#8b5cf6', '#ec4899', '#14b8a6']

export default async function UserDetailPage({ params }: { params: Promise<{ email: string }> }) {
  const { email } = await params
  const query = decodeURIComponent(email).trim().toLowerCase()

  // Find user by email, name, or ID
  const [authUsers, profiles] = await Promise.all([getAuthUsers(), getProfiles()])
  let authUser = authUsers.find(u =>
    u.email.toLowerCase() === query ||
    u.id.toLowerCase() === query
  )
  if (!authUser) {
    const matchedProfile = profiles.find(p =>
      p.display_name?.toLowerCase().includes(query)
    )
    if (matchedProfile) {
      authUser = authUsers.find(u => u.id === matchedProfile.id)
    }
  }

  if (!authUser) {
    return (
      <div>
        <Link href="/users" className="text-sm text-[var(--primary)] hover:underline mb-4 inline-block">&larr; 사용자 목록</Link>
        <div className="bg-white rounded-2xl p-12 shadow-sm border border-[var(--border)] text-center">
          <p className="text-4xl mb-4">🔍</p>
          <h2 className="text-lg font-bold mb-2">사용자를 찾을 수 없습니다</h2>
          <p className="text-[var(--text-secondary)]">{query}</p>
        </div>
      </div>
    )
  }

  const [events, errors, workspaces, members] = await Promise.all([
    getAppEventsByUser(authUser.id),
    getErrorLogsByUser(authUser.id),
    getWorkspaces(),
    getWorkspaceMembers(),
  ])

  const profile = profiles.find(p => p.id === authUser.id)
  const userWorkspaces = members
    .filter(m => m.user_id === authUser.id)
    .map(m => workspaces.find(w => w.id === m.workspace_id))
    .filter(Boolean)

  // Screen visit distribution
  const screenViews = events.filter(e => e.event_type === 'screen_view')
  const screenCounts = screenViews.reduce((acc, e) => {
    acc[e.event_name] = (acc[e.event_name] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  const screenPieData = Object.entries(screenCounts)
    .sort(([, a], [, b]) => b - a)
    .map(([name, value], i) => ({
      name,
      value,
      color: SCREEN_COLORS[i % SCREEN_COLORS.length],
    }))

  // Hourly pattern
  const hourCounts = Array.from({ length: 24 }, (_, i) => ({ hour: `${i}시`, count: 0 }))
  events.forEach(e => {
    const h = new Date(e.created_at).getHours()
    hourCounts[h].count++
  })

  // Daily activity (last 14 days)
  const now = new Date()
  const dailyActivity = Array.from({ length: 14 }, (_, i) => {
    const d = new Date(now)
    d.setDate(d.getDate() - (13 - i))
    const dateStr = d.toISOString().slice(0, 10)
    return {
      date: `${d.getMonth() + 1}/${d.getDate()}`,
      events: events.filter(e => e.created_at.slice(0, 10) === dateStr).length,
    }
  })

  const lastActive = events.length > 0 ? formatDateTime(events[0].created_at) : '-'
  const peakHour = hourCounts.reduce((max, h) => h.count > max.count ? h : max, hourCounts[0])

  return (
    <div>
      <Link href="/users" className="text-sm text-[var(--primary)] hover:underline mb-4 inline-block">&larr; 사용자 목록</Link>

      <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)] mb-6">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-[var(--primary)] flex items-center justify-center">
            <span className="text-2xl font-bold text-white">
              {(profile?.display_name || authUser.email)[0].toUpperCase()}
            </span>
          </div>
          <div>
            <h1 className="text-xl font-bold">{profile?.display_name || '(이름 없음)'}</h1>
            <p className="text-sm text-[var(--text-secondary)]">{authUser.email}</p>
            <div className="flex flex-wrap gap-2 mt-2 text-xs text-[var(--text-secondary)]">
              <span>가입: {profile ? formatDate(profile.created_at) : '-'}</span>
              <span>방식: {profile?.provider || '-'}</span>
              {userWorkspaces.map((ws, i) => (
                <span key={i} className="px-2 py-0.5 bg-indigo-50 text-indigo-700 rounded-full">{ws!.name}</span>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--primary)]">{events.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">총 활동</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--danger)]">{errors.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">에러 발생</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--success)]">{peakHour.hour}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">주 활동 시간</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-sm font-bold text-[var(--warning)]">{lastActive}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">마지막 활동</p>
        </div>
      </div>

      <UserActivityCharts screenPieData={screenPieData} hourlyData={hourCounts} dailyActivity={dailyActivity} />

      {errors.length > 0 && (
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)] mt-6">
          <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">에러 기록</h3>
          <div className="space-y-3">
            {errors.slice(0, 10).map((err) => (
              <div key={err.id} className="flex items-start justify-between py-2 border-b border-[var(--border)] last:border-0">
                <div>
                  <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-red-50 text-red-700 mr-2">{err.error_type}</span>
                  <span className="text-sm">{err.error_message}</span>
                </div>
                <span className="text-xs text-[var(--text-secondary)] whitespace-nowrap ml-4">{formatDateTime(err.created_at)}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)] mt-6">
        <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">최근 활동 로그</h3>
        <div className="space-y-2">
          {events.slice(0, 20).map((e) => (
            <div key={e.id} className="flex items-center gap-3 py-2 border-b border-[var(--border)] last:border-0">
              <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${
                e.event_type === 'screen_view' ? 'bg-indigo-50 text-indigo-700' :
                e.event_type === 'action' ? 'bg-green-50 text-green-700' :
                'bg-slate-100 text-slate-700'
              }`}>{e.event_type}</span>
              <span className="text-sm font-medium">{e.event_name}</span>
              <span className="text-xs text-[var(--text-secondary)] ml-auto">{formatDateTime(e.created_at)}</span>
            </div>
          ))}
          {events.length === 0 && (
            <p className="text-sm text-[var(--text-secondary)] text-center py-4">활동 기록이 없습니다</p>
          )}
        </div>
      </div>
    </div>
  )
}
