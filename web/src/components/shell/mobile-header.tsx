"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const TITLES: Record<string, string> = {
  "/dashboard": "홈",
  "/sponsorships": "협찬",
  "/settlements": "정산",
  "/notes": "노트",
  "/calendar": "캘린더",
  "/search": "검색",
  "/settings": "설정",
};

export function MobileHeader() {
  const pathname = usePathname();
  const base = "/" + (pathname.split("/").filter(Boolean)[0] ?? "");
  const title = TITLES[base] ?? "Influe";

  return (
    <header
      className="lg:hidden sticky top-0 z-30 flex items-center justify-between h-14 px-4 safe-pt"
      style={{
        background: "color-mix(in srgb, var(--surface) 88%, transparent)",
        backdropFilter: "saturate(180%) blur(20px)",
        WebkitBackdropFilter: "saturate(180%) blur(20px)",
        borderBottom: "1px solid var(--border)",
      }}
    >
      <h1 className="text-base font-bold tracking-tight">
        {pathname === "/dashboard" ? <span className="text-gradient">Influe</span> : title}
      </h1>
      <div className="flex items-center gap-1">
        <Link href="/search" aria-label="검색" className="w-9 h-9 flex items-center justify-center rounded-full" style={{ color: "var(--text-secondary)" }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="7" />
            <path d="m21 21-4.3-4.3" />
          </svg>
        </Link>
        <Link href="/settings" aria-label="설정" className="w-9 h-9 flex items-center justify-center rounded-full" style={{ color: "var(--text-secondary)" }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="12" cy="12" r="3" />
            <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.1a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.1a1.65 1.65 0 0 0 1.51-1 1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.1a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.1a1.65 1.65 0 0 0-1.51 1z" />
          </svg>
        </Link>
      </div>
    </header>
  );
}
