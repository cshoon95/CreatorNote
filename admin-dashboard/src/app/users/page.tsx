import { getProfiles, getWorkspaces, getWorkspaceMembers, getAppEvents, getAuthUsers, formatDate } from '@/lib/queries'
import { UsersTable } from './users-table'
import { SearchUser } from './search-user'

export const dynamic = 'force-dynamic'

export default async function UsersPage() {
  const [profiles, workspaces, members, events, authUsers] = await Promise.all([
    getProfiles(),
    getWorkspaces(),
    getWorkspaceMembers(),
    getAppEvents(1000),
    getAuthUsers(),
  ])

  const emailMap = Object.fromEntries(authUsers.map(u => [u.id, u.email]))

  // Last active per user
  const lastActive = events.reduce((acc, e) => {
    if (!e.user_id) return acc
    if (!acc[e.user_id] || e.created_at > acc[e.user_id]) {
      acc[e.user_id] = e.created_at
    }
    return acc
  }, {} as Record<string, string>)

  // Event count per user
  const eventCounts = events.reduce((acc, e) => {
    if (!e.user_id) return acc
    acc[e.user_id] = (acc[e.user_id] || 0) + 1
    return acc
  }, {} as Record<string, number>)

  const usersWithData = profiles.map(p => {
    const memberOf = members.filter(m => m.user_id === p.id)
    const ws = memberOf.map(m => workspaces.find(w => w.id === m.workspace_id)?.name).filter(Boolean)
    return {
      ...p,
      email: emailMap[p.id] ?? '-',
      workspaces: ws.join(', ') || '-',
      created_at_formatted: formatDate(p.created_at),
      last_active: lastActive[p.id] ? formatDate(lastActive[p.id]) : '-',
      event_count: eventCounts[p.id] ?? 0,
    }
  })

  const today = new Date().toISOString().slice(0, 10)
  const activeToday = new Set(events.filter(e => e.created_at.slice(0, 10) === today).map(e => e.user_id)).size

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">사용자 관리</h1>
      <SearchUser />
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--primary)]">{profiles.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">전체 사용자</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--success)]">{activeToday}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">오늘 활성</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold text-[var(--warning)]">{workspaces.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">워크스페이스</p>
        </div>
        <div className="bg-white rounded-2xl p-5 shadow-sm border border-[var(--border)]">
          <p className="text-2xl font-bold" style={{ color: '#8b5cf6' }}>{members.length}</p>
          <p className="text-sm text-[var(--text-secondary)] mt-1">멤버십</p>
        </div>
      </div>
      <UsersTable users={usersWithData} />
    </div>
  )
}
