'use client'

import { useRouter } from 'next/navigation'
import { useState } from 'react'

export function SearchUser() {
  const [query, setQuery] = useState('')
  const router = useRouter()

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    if (query.trim()) {
      router.push(`/users/${encodeURIComponent(query.trim())}`)
    }
  }

  return (
    <form onSubmit={handleSearch} className="flex gap-3 mb-6">
      <input
        type="text"
        placeholder="이름, 이메일 또는 ID로 검색..."
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        className="flex-1 max-w-md px-4 py-3 border border-[var(--border)] rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[var(--primary)] focus:border-transparent"
      />
      <button
        type="submit"
        className="px-6 py-3 bg-[var(--primary)] text-white rounded-xl text-sm font-medium hover:opacity-90 transition-opacity"
      >
        분석
      </button>
    </form>
  )
}
