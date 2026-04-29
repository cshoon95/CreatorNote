'use client'

import { DataTable } from '@/components/data-table'
import type { AppEvent } from '@/lib/types'

type EventRow = AppEvent & {
  user_name: string
  created_formatted: string
}

export function EventsClient({ data }: { data: EventRow[] }) {
  return (
    <DataTable
      data={data}
      searchKey="event_name"
      searchPlaceholder="이벤트 검색..."
      columns={[
        { key: 'created_formatted', label: '시간' },
        { key: 'event_type', label: '유형', render: (e) => (
          <span className={`text-xs font-medium px-2 py-1 rounded-full ${
            e.event_type === 'screen_view' ? 'bg-indigo-50 text-indigo-700' :
            e.event_type === 'action' ? 'bg-green-50 text-green-700' :
            'bg-slate-100 text-slate-700'
          }`}>
            {e.event_type}
          </span>
        )},
        { key: 'event_name', label: '이벤트명', render: (e) => (
          <span className="font-medium">{e.event_name}</span>
        )},
        { key: 'user_name', label: '사용자' },
      ]}
    />
  )
}
