"use client";

import { useState } from "react";
import Link from "next/link";
import { Card } from "@/components/ui/card";
import { ReelsBadge } from "@/components/ui/status-badge";
import { EmptyState } from "@/components/ui/empty-state";
import { PageHeader } from "@/components/ui/page-header";
import type { ReelsNote, GeneralNote } from "@/lib/types";

type Tab = "reels" | "general";

export function NotesTabs({
  reelsNotes,
  generalNotes,
}: {
  reelsNotes: ReelsNote[];
  generalNotes: GeneralNote[];
}) {
  const [tab, setTab] = useState<Tab>("reels");
  const [query, setQuery] = useState("");

  const list: (ReelsNote | GeneralNote)[] = tab === "reels" ? reelsNotes : generalNotes;
  const visible = query.trim()
    ? list.filter((n) => {
        const q = query.toLowerCase();
        return (
          n.title.toLowerCase().includes(q) ||
          n.plain_content.toLowerCase().includes(q) ||
          n.tags.some((t) => t.toLowerCase().includes(q))
        );
      })
    : list;

  const newHref = tab === "reels" ? "/notes/reels/new" : "/notes/general/new";

  return (
    <div>
      <PageHeader
        title="노트"
        subtitle={tab === "reels" ? "릴스 기획·스크립트 노트" : "일반 메모"}
        action={
          <Link href={newHref} className="btn btn-primary">
            + 새 노트
          </Link>
        }
      />
      <div
        className="grid grid-cols-2 gap-1 mb-4 p-1 rounded-2xl"
        style={{ background: "var(--muted)", border: "1px solid var(--border)" }}
      >
        {(
          [
            { v: "reels" as Tab, label: `🎬 릴스`, count: reelsNotes.length },
            { v: "general" as Tab, label: `📝 메모`, count: generalNotes.length },
          ]
        ).map((t) => {
          const active = tab === t.v;
          return (
            <button
              key={t.v}
              onClick={() => setTab(t.v)}
              className="py-2.5 rounded-xl text-sm font-semibold flex items-center justify-center gap-2 transition-all"
              style={{
                background: active ? "var(--surface)" : "transparent",
                color: active ? "var(--text)" : "var(--text-secondary)",
                boxShadow: active ? "var(--shadow-sm)" : undefined,
              }}
            >
              {t.label}
              <span className="text-[11px] opacity-60 tabular">{t.count}</span>
            </button>
          );
        })}
      </div>

      <input
        className="input mb-4"
        placeholder="제목·내용·태그 검색"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      {visible.length === 0 ? (
        <EmptyState
          emoji="📝"
          title={tab === "reels" ? "릴스 노트가 없어요" : "메모가 없어요"}
          description="아이디어·스크립트·촬영 메모를 자유롭게 적어두세요"
          action={{ label: "첫 노트 작성", href: newHref }}
        />
      ) : (
        <ul className="grid grid-cols-1 md:grid-cols-2 gap-2">
          {visible.map((n) => (
            <li key={n.id}>
              <NoteRow note={n} kind={tab} />
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function NoteRow({
  note,
  kind,
}: {
  note: ReelsNote | GeneralNote;
  kind: Tab;
}) {
  const href = kind === "reels" ? `/notes/reels/${note.id}` : `/notes/general/${note.id}`;
  return (
    <Link href={href}>
      <Card hover padding="md" className="h-full flex items-start gap-3">
        <div
          className="w-12 h-12 rounded-xl flex items-center justify-center text-xl flex-shrink-0"
          style={{
            background:
              kind === "reels"
                ? "linear-gradient(135deg, #7c3aed, #ec4899)"
                : "linear-gradient(135deg, #06b6d4, #8b5cf6)",
          }}
        >
          {kind === "reels" ? "🎬" : "📝"}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            {note.is_pinned && <span className="text-xs">📌</span>}
            <p className="text-sm font-bold truncate">{note.title || "제목 없음"}</p>
            {kind === "reels" && <ReelsBadge status={(note as ReelsNote).status} />}
          </div>
          <p className="text-xs truncate" style={{ color: "var(--text-secondary)" }}>
            {note.plain_content || "내용 없음"}
          </p>
          {note.tags.length > 0 && (
            <div className="flex gap-1 mt-1.5 flex-wrap">
              {note.tags.slice(0, 4).map((t) => (
                <span
                  key={t}
                  className="text-[10px] px-1.5 py-0.5 rounded-full font-semibold"
                  style={{ background: "var(--brand-soft)", color: "var(--brand)" }}
                >
                  #{t}
                </span>
              ))}
            </div>
          )}
        </div>
      </Card>
    </Link>
  );
}
