'use client'

import { DataTable } from '@/components/data-table'
import type { ErrorLog } from '@/lib/types'

type ErrorRow = ErrorLog & {
  user_name: string
  created_formatted: string
  app_version: string
  os_version: string
}

export function ErrorsClient({ data }: { data: ErrorRow[] }) {
  return (
    <DataTable
      data={data}
      searchKey="error_message"
      searchPlaceholder="에러 메시지 검색..."
      columns={[
        { key: 'created_formatted', label: '시간' },
        { key: 'error_type', label: '유형', render: (e) => (
          <span className={`text-xs font-medium px-2 py-1 rounded-full ${
            e.error_type === 'api' ? 'bg-orange-50 text-orange-700' :
            e.error_type === 'runtime' ? 'bg-red-50 text-red-700' :
            'bg-slate-100 text-slate-700'
          }`}>
            {e.error_type}
          </span>
        )},
        { key: 'error_message', label: '에러 메시지', render: (e) => (
          <div className="max-w-md">
            <p className="text-sm font-medium truncate">{e.error_message}</p>
            {e.screen && <p className="text-xs text-[var(--text-secondary)]">화면: {e.screen}</p>}
          </div>
        )},
        { key: 'user_name', label: '사용자' },
        { key: 'app_version', label: '버전' },
        { key: 'os_version', label: 'OS' },
      ]}
    />
  )
}
