"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

interface FabConfig {
  href: string;
  label: string;
  emoji: string;
}

const MATCH: { test: (path: string) => boolean; cfg: FabConfig }[] = [
  { test: (p) => p === "/dashboard", cfg: { href: "/sponsorships/new", label: "새 협찬", emoji: "🤝" } },
  { test: (p) => p.startsWith("/sponsorships"), cfg: { href: "/sponsorships/new", label: "새 협찬", emoji: "🤝" } },
  { test: (p) => p.startsWith("/settlements"), cfg: { href: "/settlements/new", label: "새 정산", emoji: "💰" } },
  { test: (p) => p.startsWith("/notes"), cfg: { href: "/notes/reels/new", label: "새 노트", emoji: "🎬" } },
];

const SKIP_PATHS = [
  "/sponsorships/new",
  "/settlements/new",
  "/notes/reels/new",
  "/notes/general/new",
];

export function Fab() {
  const pathname = usePathname();
  if (SKIP_PATHS.includes(pathname) || pathname.includes("/edit")) return null;
  const match = MATCH.find((m) => m.test(pathname));
  if (!match) return null;
  return (
    <Link
      href={match.cfg.href}
      aria-label={match.cfg.label}
      className="lg:hidden fixed right-4 z-30 w-14 h-14 rounded-full flex items-center justify-center text-2xl shadow-lg active:scale-95 transition-transform"
      style={{
        bottom: "calc(env(safe-area-inset-bottom) + 4.5rem)",
        background: "var(--brand)",
        color: "white",
        boxShadow: "var(--shadow-lg)",
      }}
    >
      {match.cfg.emoji}
    </Link>
  );
}
