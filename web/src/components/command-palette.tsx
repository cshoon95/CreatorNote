"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useWorkspace } from "@/components/workspace-context";
import { formatKrw, formatDate } from "@/lib/format";
import type { Sponsorship, ReelsNote, GeneralNote } from "@/lib/types";

interface CommandItem {
  id: string;
  group: "탐색" | "협찬" | "릴스" | "메모" | "액션";
  label: string;
  hint?: string;
  emoji: string;
  onSelect: () => void;
}

export function CommandPalette() {
  const router = useRouter();
  const ws = useWorkspace();
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [data, setData] = useState<{
    sponsors: Sponsorship[];
    reels: ReelsNote[];
    generals: GeneralNote[];
  }>({ sponsors: [], reels: [], generals: [] });
  const [active, setActive] = useState(0);

  // Global ⌘K / Ctrl+K
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const tag = (e.target as HTMLElement)?.tagName;
      const inField = tag === "INPUT" || tag === "TEXTAREA" || (e.target as HTMLElement)?.isContentEditable;
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen((o) => !o);
        return;
      }
      if (!inField && e.key === "/") {
        e.preventDefault();
        setOpen(true);
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, []);

  // Lazy load workspace data when first opened
  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    (async () => {
      const supabase = createClient();
      const [s, r, g] = await Promise.all([
        supabase.from("sponsorships").select("*").eq("workspace_id", ws.workspaceId),
        supabase.from("reels_notes").select("*").eq("workspace_id", ws.workspaceId),
        supabase.from("general_notes").select("*").eq("workspace_id", ws.workspaceId),
      ]);
      if (cancelled) return;
      setData({
        sponsors: (s.data ?? []) as Sponsorship[],
        reels: (r.data ?? []) as ReelsNote[],
        generals: (g.data ?? []) as GeneralNote[],
      });
    })();
    return () => {
      cancelled = true;
    };
  }, [open, ws.workspaceId]);

  const navItems: CommandItem[] = useMemo(
    () => [
      { id: "nav-dashboard", group: "탐색", emoji: "🏠", label: "홈", onSelect: () => router.push("/dashboard") },
      { id: "nav-sponsors", group: "탐색", emoji: "🤝", label: "협찬", onSelect: () => router.push("/sponsorships") },
      { id: "nav-settlements", group: "탐색", emoji: "💰", label: "정산", onSelect: () => router.push("/settlements") },
      { id: "nav-notes", group: "탐색", emoji: "📝", label: "노트", onSelect: () => router.push("/notes") },
      { id: "nav-calendar", group: "탐색", emoji: "📅", label: "캘린더", onSelect: () => router.push("/calendar") },
      { id: "nav-report", group: "탐색", emoji: "📊", label: "월 리포트", onSelect: () => router.push("/settlements/report") },
      { id: "nav-settings", group: "탐색", emoji: "⚙️", label: "설정", onSelect: () => router.push("/settings") },
      { id: "act-new-sponsor", group: "액션", emoji: "➕", label: "새 협찬", hint: "추가", onSelect: () => router.push("/sponsorships/new") },
      { id: "act-new-settle", group: "액션", emoji: "➕", label: "새 정산", hint: "추가", onSelect: () => router.push("/settlements/new") },
      { id: "act-new-reels", group: "액션", emoji: "🎬", label: "새 릴스 노트", hint: "추가", onSelect: () => router.push("/notes/reels/new") },
      { id: "act-new-general", group: "액션", emoji: "📝", label: "새 메모", hint: "추가", onSelect: () => router.push("/notes/general/new") },
    ],
    [router],
  );

  const items: CommandItem[] = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return navItems;
    const matchNav = navItems.filter((i) => i.label.toLowerCase().includes(q));
    const matchSponsors: CommandItem[] = data.sponsors
      .filter(
        (s) =>
          s.brand_name.toLowerCase().includes(q) ||
          (s.product_name ?? "").toLowerCase().includes(q),
      )
      .slice(0, 6)
      .map((s) => ({
        id: `s-${s.id}`,
        group: "협찬",
        emoji: "🤝",
        label: s.brand_name,
        hint: `${s.product_name ?? ""} · ${formatKrw(s.amount)} · ${formatDate(s.end_date)}`.replace(/^ · /, ""),
        onSelect: () => router.push(`/sponsorships/${s.id}`),
      }));
    const matchReels: CommandItem[] = data.reels
      .filter(
        (n) =>
          n.title.toLowerCase().includes(q) ||
          n.plain_content.toLowerCase().includes(q) ||
          n.tags.some((t) => t.toLowerCase().includes(q)),
      )
      .slice(0, 6)
      .map((n) => ({
        id: `r-${n.id}`,
        group: "릴스",
        emoji: "🎬",
        label: n.title || "제목 없음",
        hint: n.plain_content.slice(0, 60),
        onSelect: () => router.push(`/notes/reels/${n.id}`),
      }));
    const matchGenerals: CommandItem[] = data.generals
      .filter(
        (n) =>
          n.title.toLowerCase().includes(q) ||
          n.plain_content.toLowerCase().includes(q) ||
          n.tags.some((t) => t.toLowerCase().includes(q)),
      )
      .slice(0, 6)
      .map((n) => ({
        id: `g-${n.id}`,
        group: "메모",
        emoji: "📝",
        label: n.title || "제목 없음",
        hint: n.plain_content.slice(0, 60),
        onSelect: () => router.push(`/notes/general/${n.id}`),
      }));
    return [...matchSponsors, ...matchReels, ...matchGenerals, ...matchNav];
  }, [query, navItems, data, router]);

  // Reset active when items change
  useEffect(() => {
    setActive(0);
  }, [query]);

  // Arrow nav inside palette
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        setOpen(false);
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        setActive((a) => Math.min(items.length - 1, a + 1));
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        setActive((a) => Math.max(0, a - 1));
      } else if (e.key === "Enter") {
        e.preventDefault();
        const it = items[active];
        if (it) {
          setOpen(false);
          setQuery("");
          it.onSelect();
        }
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, items, active]);

  if (!open) return null;

  // Group items in display order
  const grouped: Record<string, CommandItem[]> = {};
  for (const it of items) {
    (grouped[it.group] ??= []).push(it);
  }

  let runningIdx = -1;

  return (
    <div
      className="fixed inset-0 z-[120] flex items-start justify-center px-4 pt-24"
      style={{ background: "rgba(15, 23, 42, 0.4)", backdropFilter: "blur(6px)" }}
      onClick={() => setOpen(false)}
    >
      <div
        className="w-full max-w-xl rounded-2xl overflow-hidden pop-in"
        style={{
          background: "var(--surface)",
          border: "1px solid var(--border)",
          boxShadow: "var(--shadow-lg)",
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center gap-3 px-4 py-3 border-b" style={{ borderColor: "var(--border)" }}>
          <span style={{ color: "var(--text-tertiary)" }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="7" />
              <path d="m21 21-4.3-4.3" />
            </svg>
          </span>
          <input
            autoFocus
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="협찬, 노트, 페이지 검색..."
            className="flex-1 bg-transparent outline-none text-base"
          />
          <span
            className="text-[10px] px-1.5 py-0.5 rounded font-mono"
            style={{ background: "var(--muted)", color: "var(--text-tertiary)" }}
          >
            ESC
          </span>
        </div>
        <div className="max-h-[60vh] overflow-y-auto p-1.5">
          {items.length === 0 ? (
            <p
              className="text-center text-sm py-8"
              style={{ color: "var(--text-tertiary)" }}
            >
              결과가 없어요
            </p>
          ) : (
            Object.entries(grouped).map(([group, list]) => (
              <div key={group} className="mb-1">
                <p
                  className="text-[10px] font-bold uppercase tracking-wider px-3 py-1.5"
                  style={{ color: "var(--text-tertiary)" }}
                >
                  {group}
                </p>
                {list.map((it) => {
                  runningIdx += 1;
                  const idx = runningIdx;
                  const isActive = idx === active;
                  return (
                    <button
                      key={it.id}
                      onMouseEnter={() => setActive(idx)}
                      onClick={() => {
                        setOpen(false);
                        setQuery("");
                        it.onSelect();
                      }}
                      className="w-full text-left flex items-center gap-3 px-3 py-2 rounded-lg transition-colors"
                      style={{
                        background: isActive ? "var(--brand-soft)" : "transparent",
                        color: isActive ? "var(--brand)" : "var(--text)",
                      }}
                    >
                      <span className="text-base w-5 text-center">{it.emoji}</span>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold truncate">{it.label}</p>
                        {it.hint && (
                          <p
                            className="text-[11px] truncate"
                            style={{ color: isActive ? "var(--brand)" : "var(--text-tertiary)" }}
                          >
                            {it.hint}
                          </p>
                        )}
                      </div>
                      {isActive && (
                        <span className="text-[10px]" style={{ color: "var(--brand)" }}>
                          ↵
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>
            ))
          )}
        </div>
        <div
          className="px-4 py-2.5 text-[11px] flex items-center justify-between border-t"
          style={{ background: "var(--bg)", color: "var(--text-tertiary)", borderColor: "var(--border)" }}
        >
          <span>
            <kbd className="font-mono">↑↓</kbd> 이동 · <kbd className="font-mono">↵</kbd> 선택
          </span>
          <span>
            <kbd className="font-mono">⌘K</kbd> 또는 <kbd className="font-mono">/</kbd>
          </span>
        </div>
      </div>
    </div>
  );
}
