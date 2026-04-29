import { getAppEvents, getProfiles, formatDateTime } from '@/lib/queries'
import { EventsClient } from './events-client'

export const dynamic = 'force-dynamic'

export default async function EventsPage() {
  const [events, profiles] = await Promise.all([
    getAppEvents(1000),
    getProfiles(),
  ])

  const profileMap = Object.fromEntries(profiles.map(p => [p.id, p.display_name || '(이름 없음)']))

  const today = new Date().toISOString().slice(0, 10)
  const todayEvents = events.filter(e => e.created_at.slice(0, 10) === today)
  const todayActiveUsers = new Set(todayEvents.map(e => e.user_id)).size

  // Event type distribution
  const typeCounts = events.reduce((acc, e) => {
    acc[e.event_type] = (acc[e.event_type] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  // Most visited screens
  const screenViews = events.filter(e => e.event_type === 'screen_view')
  const screenCounts = screenViews.reduce((acc, e) => {
    acc[e.event_name] = (acc[e.event_name] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  const topScreens = Object.entries(screenCounts)
    .sort(([, a], [, b]) => b - a)

  const tableData = events.map(e => ({
    ...e,
    user_name: e.user_id ? profileMap[e.user_id] ?? e.user_id.slice(0, 8) : '-',
    created_formatted: formatDateTime(e.created_at),
  }))

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">이벤트 로그</h1>

      <div className="grid grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--primary)]">{todayEvents.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">오늘 이벤트</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--success)]">{todayActiveUsers}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">오늘 활성 사용자</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--warning)]">{events.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">전체 이벤트</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold" style={{ color: '#8b5cf6' }}>{Object.keys(typeCounts).length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">이벤트 유형</p>
        </div>
      </div>

      {topScreens.length > 0 && (
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)] mb-6">
          <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">화면별 방문 횟수</h3>
          <div className="space-y-2">
            {topScreens.map(([screen, count], i) => (
              <div key={i} className="flex items-center gap-3">
                <span className="text-xs font-bold text-[var(--primary)] w-8">{count}회</span>
                <div className="flex-1 bg-indigo-50 rounded-lg h-6 overflow-hidden">
                  <div
                    className="bg-indigo-200 h-full rounded-lg"
                    style={{ width: `${(count / topScreens[0][1]) * 100}%` }}
                  />
                </div>
                <span className="text-sm font-medium w-20">{screen}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <EventsClient data={tableData} />
    </div>
  )
}
