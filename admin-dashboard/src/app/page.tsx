import { getProfiles, getAppEvents, getErrorLogs, formatDateTime } from '@/lib/queries'
import { KPICard } from '@/components/kpi-card'
import { DashboardCharts } from './dashboard-charts'

export const dynamic = 'force-dynamic'

const SCREEN_COLORS = ['#6366f1', '#f59e0b', '#22c55e', '#ef4444', '#3b82f6', '#8b5cf6', '#ec4899', '#14b8a6']

export default async function DashboardPage() {
  const [profiles, events, errors] = await Promise.all([
    getProfiles(),
    getAppEvents(1000),
    getErrorLogs(200),
  ])

  const totalUsers = profiles.length
  const totalEvents = events.length
  const totalErrors = errors.length

  // Active users today
  const today = new Date().toISOString().slice(0, 10)
  const todayEvents = events.filter(e => e.created_at.slice(0, 10) === today)
  const activeUsersToday = new Set(todayEvents.map(e => e.user_id)).size
  const todayErrors = errors.filter(e => e.created_at.slice(0, 10) === today).length

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

  // Hourly distribution
  const hourCounts = Array.from({ length: 24 }, (_, i) => ({ hour: `${i}시`, count: 0 }))
  events.forEach(e => {
    const h = new Date(e.created_at).getHours()
    hourCounts[h].count++
  })

  // Daily trend (last 7 days)
  const now = new Date()
  const dailyTrend = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(now)
    d.setDate(d.getDate() - (6 - i))
    const dateStr = d.toISOString().slice(0, 10)
    const dayEvents = events.filter(e => e.created_at.slice(0, 10) === dateStr)
    const dayUsers = new Set(dayEvents.map(e => e.user_id)).size
    return {
      date: `${d.getMonth() + 1}/${d.getDate()}`,
      users: dayUsers,
      events: dayEvents.length,
    }
  })

  // Error trend (last 7 days)
  const errorTrend = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(now)
    d.setDate(d.getDate() - (6 - i))
    const dateStr = d.toISOString().slice(0, 10)
    return {
      date: `${d.getMonth() + 1}/${d.getDate()}`,
      count: errors.filter(e => e.created_at.slice(0, 10) === dateStr).length,
    }
  })

  // Recent errors
  const recentErrors = errors.slice(0, 5)

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">모니터링 대시보드</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KPICard icon="👥" title="총 사용자" value={totalUsers} color="var(--primary)" />
        <KPICard icon="🟢" title="오늘 활성 사용자" value={activeUsersToday} color="var(--success)" />
        <KPICard icon="📋" title="총 이벤트" value={totalEvents} subtitle="최근 500건" color="var(--warning)" />
        <KPICard icon="🚨" title="오늘 에러" value={todayErrors} subtitle={`전체 ${totalErrors}건`} color="var(--danger)" />
      </div>

      <DashboardCharts
        screenPieData={screenPieData}
        hourlyData={hourCounts}
        dailyTrend={dailyTrend}
        errorTrend={errorTrend}
      />

      <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)] mt-6">
        <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">최근 에러</h3>
        <div className="space-y-3">
          {recentErrors.map((err) => (
            <div key={err.id} className="flex items-start justify-between py-3 border-b border-[var(--border)] last:border-0">
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-medium px-2 py-0.5 rounded-full bg-red-50 text-red-700">
                    {err.error_type}
                  </span>
                  {err.screen && (
                    <span className="text-xs text-[var(--text-secondary)]">{err.screen}</span>
                  )}
                </div>
                <p className="text-sm font-medium text-[var(--text)]">{err.error_message}</p>
                {err.device_info?.app_version && (
                  <p className="text-xs text-[var(--text-secondary)] mt-1">
                    v{err.device_info.app_version} (build {err.device_info.build}) · {err.device_info.os}
                  </p>
                )}
              </div>
              <span className="text-xs text-[var(--text-secondary)] whitespace-nowrap ml-4">
                {formatDateTime(err.created_at)}
              </span>
            </div>
          ))}
          {recentErrors.length === 0 && (
            <p className="text-sm text-[var(--text-secondary)] text-center py-4">에러가 없습니다</p>
          )}
        </div>
      </div>
    </div>
  )
}
