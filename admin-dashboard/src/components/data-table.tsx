'use client'

import { useState } from 'react'

interface Column<T> {
  key: string
  label: string
  render?: (item: T) => React.ReactNode
}

interface DataTableProps<T> {
  data: T[]
  columns: Column<T>[]
  searchKey?: string
  searchPlaceholder?: string
}

export function DataTable<T extends object>({
  data,
  columns,
  searchKey,
  searchPlaceholder = '검색...',
}: DataTableProps<T>) {
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(0)
  const pageSize = 20

  const filtered = searchKey
    ? data.filter((item) =>
        String((item as Record<string, unknown>)[searchKey] ?? '').toLowerCase().includes(search.toLowerCase())
      )
    : data

  const paged = filtered.slice(page * pageSize, (page + 1) * pageSize)
  const totalPages = Math.ceil(filtered.length / pageSize)

  return (
    <div>
      {searchKey && (
        <div className="mb-4">
          <input
            type="text"
            placeholder={searchPlaceholder}
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(0) }}
            className="w-full max-w-sm px-4 py-2 border border-[var(--border)] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-transparent"
          />
        </div>
      )}
      <div className="bg-white rounded-2xl shadow-sm border border-[var(--border)] overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border)] bg-slate-50">
              {columns.map((col) => (
                <th key={col.key} className="text-left px-4 py-3 font-semibold text-[var(--text-secondary)]">
                  {col.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {paged.map((item, i) => (
              <tr key={i} className="border-b border-[var(--border)] last:border-0 hover:bg-slate-50">
                {columns.map((col) => (
                  <td key={col.key} className="px-4 py-3">
                    {col.render ? col.render(item) : String((item as Record<string, unknown>)[col.key] ?? '-')}
                  </td>
                ))}
              </tr>
            ))}
            {paged.length === 0 && (
              <tr>
                <td colSpan={columns.length} className="px-4 py-8 text-center text-[var(--text-secondary)]">
                  데이터가 없습니다
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4 text-sm text-[var(--text-secondary)]">
          <span>총 {filtered.length}건 중 {page * pageSize + 1}-{Math.min((page + 1) * pageSize, filtered.length)}건</span>
          <div className="flex gap-2">
            <button
              onClick={() => setPage(Math.max(0, page - 1))}
              disabled={page === 0}
              className="px-3 py-1 rounded-lg border border-[var(--border)] disabled:opacity-40 hover:bg-slate-50"
            >
              이전
            </button>
            <button
              onClick={() => setPage(Math.min(totalPages - 1, page + 1))}
              disabled={page >= totalPages - 1}
              className="px-3 py-1 rounded-lg border border-[var(--border)] disabled:opacity-40 hover:bg-slate-50"
            >
              다음
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
