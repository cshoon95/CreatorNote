'use client'

import { useRouter } from 'next/navigation'
import { DataTable } from '@/components/data-table'
import type { Profile } from '@/lib/types'

type UserRow = Profile & {
  email: string
  workspaces: string
  created_at_formatted: string
  last_active: string
  event_count: number
}

export function UsersTable({ users }: { users: UserRow[] }) {
  const router = useRouter()

  return (
    <DataTable
      data={users}
      searchKey="display_name"
      searchPlaceholder="이름 검색..."
      columns={[
        { key: 'display_name', label: '이름', render: (u) => (
          <button
            onClick={() => router.push(`/users/${encodeURIComponent(u.email)}`)}
            className="font-medium text-[var(--primary)] hover:underline"
          >
            {u.display_name || '(없음)'}
          </button>
        )},
        { key: 'email', label: '이메일', render: (u) => (
          <span className="text-sm">{u.email}</span>
        )},
        { key: 'provider', label: '가입', render: (u) => (
          <span className="text-xs px-2 py-1 rounded-full bg-slate-100">{u.provider || '-'}</span>
        )},
        { key: 'event_count', label: '활동', render: (u) => (
          <span className="font-semibold">{u.event_count}</span>
        )},
        { key: 'last_active', label: '마지막 활동' },
        { key: 'created_at_formatted', label: '가입일' },
      ]}
    />
  )
}
