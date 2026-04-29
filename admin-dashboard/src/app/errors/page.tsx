import { getErrorLogs, getProfiles, formatDateTime } from '@/lib/queries'
import { ErrorsClient } from './errors-client'

export const dynamic = 'force-dynamic'

export default async function ErrorsPage() {
  const [errors, profiles] = await Promise.all([
    getErrorLogs(500),
    getProfiles(),
  ])

  const profileMap = Object.fromEntries(profiles.map(p => [p.id, p.display_name || '(이름 없음)']))

  const today = new Date().toISOString().slice(0, 10)
  const todayCount = errors.filter(e => e.created_at.slice(0, 10) === today).length

  // Error type distribution
  const typeCounts = errors.reduce((acc, e) => {
    acc[e.error_type] = (acc[e.error_type] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  // Top error messages
  const msgCounts = errors.reduce((acc, e) => {
    const key = e.error_message.slice(0, 100)
    acc[key] = (acc[key] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  const topErrors = Object.entries(msgCounts)
    .sort(([, a], [, b]) => b - a)
    .slice(0, 10)

  const tableData = errors.map(e => ({
    ...e,
    user_name: e.user_id ? profileMap[e.user_id] ?? e.user_id.slice(0, 8) : '-',
    created_formatted: formatDateTime(e.created_at),
    app_version: e.device_info?.app_version ?? '-',
    os_version: e.device_info?.os ?? '-',
  }))

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">에러 로그</h1>

      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--danger)]">{todayCount}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">오늘 에러</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--warning)]">{errors.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">전체 에러</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--primary)]">{Object.keys(typeCounts).length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">에러 유형</p>
        </div>
      </div>

      {topErrors.length > 0 && (
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-[var(--border)] mb-6">
          <h3 className="text-sm font-semibold text-[var(--text-secondary)] mb-4">자주 발생하는 에러 Top 10</h3>
          <div className="space-y-2">
            {topErrors.map(([msg, count], i) => (
              <div key={i} className="flex items-center gap-3">
                <span className="text-xs font-bold text-[var(--danger)] w-8">{count}회</span>
                <div className="flex-1 bg-red-50 rounded-lg h-6 overflow-hidden">
                  <div
                    className="bg-red-200 h-full rounded-lg"
                    style={{ width: `${(count / topErrors[0][1]) * 100}%` }}
                  />
                </div>
                <span className="text-xs text-[var(--text)] truncate max-w-md">{msg}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <ErrorsClient data={tableData} />
    </div>
  )
}
