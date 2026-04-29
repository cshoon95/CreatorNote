'use client'

import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import { useState } from 'react'

const navItems = [
  { href: '/', label: '대시보드', icon: '📊' },
  { href: '/users', label: '사용자', icon: '👥' },
  { href: '/errors', label: '에러 로그', icon: '🚨' },
  { href: '/events', label: '이벤트 로그', icon: '📋' },
]

export function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const [open, setOpen] = useState(false)

  const handleLogout = async () => {
    await fetch('/api/logout', { method: 'POST' })
    router.push('/login')
    router.refresh()
  }

  return (
    <>
      {/* Mobile header */}
      <div className="lg:hidden fixed top-0 left-0 right-0 h-14 bg-white border-b border-[var(--border)] flex items-center px-4 z-50">
        <button onClick={() => setOpen(!open)} className="p-2 -ml-2">
          <svg width="24" height="24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
            {open ? (
              <><line x1="6" y1="6" x2="18" y2="18" /><line x1="6" y1="18" x2="18" y2="6" /></>
            ) : (
              <><line x1="3" y1="6" x2="21" y2="6" /><line x1="3" y1="12" x2="21" y2="12" /><line x1="3" y1="18" x2="21" y2="18" /></>
            )}
          </svg>
        </button>
        <h1 className="text-lg font-bold text-[var(--primary)] ml-3">Influe Monitor</h1>
      </div>

      {/* Mobile overlay */}
      {open && (
        <div className="lg:hidden fixed inset-0 bg-black/30 z-40" onClick={() => setOpen(false)} />
      )}

      {/* Sidebar */}
      <aside className={`fixed left-0 top-0 h-full w-64 bg-white border-r border-[var(--border)] flex flex-col z-50 transition-transform lg:translate-x-0 ${open ? 'translate-x-0' : '-translate-x-full'}`}>
        <div className="p-6 border-b border-[var(--border)]">
          <h1 className="text-xl font-bold text-[var(--primary)]">Influe Monitor</h1>
          <p className="text-xs text-[var(--text-secondary)] mt-1">앱 모니터링 대시보드</p>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const isActive = pathname === item.href
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setOpen(false)}
                className={`flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-[var(--primary)] text-white'
                    : 'text-[var(--text-secondary)] hover:bg-slate-50 hover:text-[var(--text)]'
                }`}
              >
                <span className="text-lg">{item.icon}</span>
                {item.label}
              </Link>
            )
          })}
        </nav>
        <div className="p-4 border-t border-[var(--border)] space-y-3">
          <button
            onClick={handleLogout}
            className="w-full px-4 py-2.5 text-sm text-[var(--danger)] hover:bg-red-50 rounded-xl transition-colors text-left"
          >
            로그아웃
          </button>
          <p className="text-xs text-[var(--text-secondary)]">Influe v1.0.5</p>
        </div>
      </aside>
    </>
  )
}
