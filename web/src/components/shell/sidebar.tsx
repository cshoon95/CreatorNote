"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { NAV_ITEMS } from "./nav-items";
import { Avatar } from "@/components/ui/avatar";
import { createClient } from "@/lib/supabase/client";

interface SidebarProps {
  workspaceName: string;
  displayName: string;
  email: string | null;
  avatarUrl: string | null;
}

export function Sidebar({ workspaceName, displayName, email, avatarUrl }: SidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const isActive = (href: string) => pathname === href || pathname.startsWith(href + "/");

  const signOut = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  };

  return (
    <aside
      className="hidden lg:flex fixed left-0 top-0 h-full w-64 flex-col z-40"
      style={{ background: "var(--surface)", borderRight: "1px solid var(--border)" }}
    >
      {/* Brand */}
      <div className="px-6 pt-6 pb-5">
        <Link href="/dashboard" className="flex items-center gap-2.5">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center"
            style={{ background: "var(--brand)" }}
          >
            <span className="text-white font-bold text-sm">I</span>
          </div>
          <div className="min-w-0">
            <p className="text-base font-bold leading-none tracking-tight">Influe</p>
            <p
              className="text-[11px] mt-1 truncate"
              style={{ color: "var(--text-tertiary)" }}
              title={workspaceName}
            >
              {workspaceName}
            </p>
          </div>
        </Link>
      </div>

      {/* Nav */}
      <nav className="flex-1 px-3 space-y-0.5 overflow-y-auto">
        {NAV_ITEMS.map((item) => {
          const active = isActive(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors"
              style={{
                background: active ? "var(--brand-soft)" : "transparent",
                color: active ? "var(--brand)" : "var(--text-secondary)",
              }}
            >
              <span className="text-[15px] w-5 text-center">{item.icon}</span>
              {item.label}
            </Link>
          );
        })}

        <div className="pt-4">
          <p
            className="text-[10px] font-bold uppercase tracking-widest px-3.5 mb-2"
            style={{ color: "var(--text-tertiary)" }}
          >
            도구
          </p>
          <Link
            href="/ai"
            className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors"
            style={{
              background: isActive("/ai") ? "var(--brand-soft)" : "transparent",
              color: isActive("/ai") ? "var(--brand)" : "var(--text-secondary)",
            }}
          >
            <span className="text-[15px] w-5 text-center">✨</span>
            AI 어시스트
          </Link>
          <Link
            href="/search"
            className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors"
            style={{
              background: isActive("/search") ? "var(--brand-soft)" : "transparent",
              color: isActive("/search") ? "var(--brand)" : "var(--text-secondary)",
            }}
          >
            <span className="text-[15px] w-5 text-center">🔍</span>
            검색
          </Link>
          <Link
            href="/settlements/report"
            className="flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-colors"
            style={{
              background: isActive("/settlements/report") ? "var(--brand-soft)" : "transparent",
              color: isActive("/settlements/report") ? "var(--brand)" : "var(--text-secondary)",
            }}
          >
            <span className="text-[15px] w-5 text-center">📊</span>
            월 리포트
          </Link>
        </div>
      </nav>

      {/* Profile */}
      <div className="p-3 border-t" style={{ borderColor: "var(--border)" }}>
        <Link
          href="/settings"
          className="flex items-center gap-3 px-2 py-2 rounded-xl transition-colors hover:bg-[var(--muted)]"
        >
          <Avatar name={displayName} url={avatarUrl} size={36} />
          <div className="flex-1 min-w-0">
            <p className="text-sm font-semibold truncate">{displayName}</p>
            <p
              className="text-[11px] truncate"
              style={{ color: "var(--text-tertiary)" }}
            >
              {email ?? "설정"}
            </p>
          </div>
          <button
            onClick={(e) => {
              e.preventDefault();
              e.stopPropagation();
              signOut();
            }}
            className="w-7 h-7 flex items-center justify-center rounded-lg hover:bg-[var(--surface)] transition-colors"
            aria-label="로그아웃"
            title="로그아웃"
            style={{ color: "var(--text-tertiary)" }}
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
              <polyline points="16 17 21 12 16 7" />
              <line x1="21" x2="9" y1="12" y2="12" />
            </svg>
          </button>
        </Link>
        <p
          className="text-[10px] text-center mt-2"
          style={{ color: "var(--text-tertiary)" }}
        >
          Influe v1.0
        </p>
      </div>
    </aside>
  );
}
