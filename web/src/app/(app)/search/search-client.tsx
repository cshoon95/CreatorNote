"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Card } from "@/components/ui/card";
import { SponsorshipBadge, ReelsBadge } from "@/components/ui/status-badge";
import { Avatar } from "@/components/ui/avatar";
import { formatKrw, formatDate } from "@/lib/format";
import type { Sponsorship, ReelsNote, GeneralNote } from "@/lib/types";

interface Props {
  sponsorships: Sponsorship[];
  reelsNotes: ReelsNote[];
  generalNotes: GeneralNote[];
}

export function SearchClient({ sponsorships, reelsNotes, generalNotes }: Props) {
  const [query, setQuery] = useState("");
  const q = query.trim().toLowerCase();

  const matched = useMemo(() => {
    if (!q) return null;
    return {
      matchedSponsors: sponsorships.filter(
        (s) =>
          s.brand_name.toLowerCase().includes(q) ||
          (s.product_name ?? "").toLowerCase().includes(q) ||
          (s.details ?? "").toLowerCase().includes(q),
      ),
      matchedReels: reelsNotes.filter(
        (n) =>
          n.title.toLowerCase().includes(q) ||
          n.plain_content.toLowerCase().includes(q) ||
          n.tags.some((t) => t.toLowerCase().includes(q)),
      ),
      matchedGenerals: generalNotes.filter(
        (n) =>
          n.title.toLowerCase().includes(q) ||
          n.plain_content.toLowerCase().includes(q) ||
          n.tags.some((t) => t.toLowerCase().includes(q)),
      ),
    };
  }, [q, sponsorships, reelsNotes, generalNotes]);

  return (
    <div>
      <div className="relative">
        <span
          className="absolute left-4 top-1/2 -translate-y-1/2"
          style={{ color: "var(--text-tertiary)" }}
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="7" />
            <path d="m21 21-4.3-4.3" />
          </svg>
        </span>
        <input
          autoFocus
          className="input text-base"
          style={{ paddingLeft: "2.75rem" }}
          placeholder="브랜드, 제목, 내용, 태그..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      {!matched ? (
        <p className="text-sm text-center py-12" style={{ color: "var(--text-secondary)" }}>
          검색어를 입력해 주세요
        </p>
      ) : matched.matchedSponsors.length === 0 &&
        matched.matchedReels.length === 0 &&
        matched.matchedGenerals.length === 0 ? (
        <p className="text-sm text-center py-12" style={{ color: "var(--text-secondary)" }}>
          검색 결과가 없어요
        </p>
      ) : (
        <div className="space-y-6 mt-5">
          {matched.matchedSponsors.length > 0 && (
            <Section title={`🤝 협찬 · ${matched.matchedSponsors.length}건`}>
              <div className="space-y-2">
                {matched.matchedSponsors.map((s) => (
                  <Link key={s.id} href={`/sponsorships/${s.id}`}>
                    <Card hover padding="md" className="flex items-center gap-3">
                      <Avatar name={s.brand_name} size={36} />
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="text-sm font-bold truncate">{s.brand_name}</p>
                          <SponsorshipBadge status={s.status} />
                        </div>
                        <p className="text-[11px] tabular" style={{ color: "var(--text-secondary)" }}>
                          {formatDate(s.start_date)} ~ {formatDate(s.end_date)} ·{" "}
                          {formatKrw(s.amount)}
                        </p>
                      </div>
                    </Card>
                  </Link>
                ))}
              </div>
            </Section>
          )}
          {matched.matchedReels.length > 0 && (
            <Section title={`🎬 릴스 노트 · ${matched.matchedReels.length}건`}>
              <div className="space-y-2">
                {matched.matchedReels.map((n) => (
                  <Link key={n.id} href={`/notes/reels/${n.id}`}>
                    <Card hover padding="md" className="flex items-center gap-3">
                      <div
                        className="w-9 h-9 rounded-lg flex items-center justify-center"
                        style={{ background: "var(--brand-soft)" }}
                      >
                        🎬
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="text-sm font-bold truncate">
                            {n.title || "제목 없음"}
                          </p>
                          <ReelsBadge status={n.status} />
                        </div>
                        <p
                          className="text-[11px] truncate"
                          style={{ color: "var(--text-secondary)" }}
                        >
                          {n.plain_content || "내용 없음"}
                        </p>
                      </div>
                    </Card>
                  </Link>
                ))}
              </div>
            </Section>
          )}
          {matched.matchedGenerals.length > 0 && (
            <Section title={`📝 메모 · ${matched.matchedGenerals.length}건`}>
              <div className="space-y-2">
                {matched.matchedGenerals.map((n) => (
                  <Link key={n.id} href={`/notes/general/${n.id}`}>
                    <Card hover padding="md" className="flex items-center gap-3">
                      <div
                        className="w-9 h-9 rounded-lg flex items-center justify-center"
                        style={{
                          background: "linear-gradient(135deg, #06b6d4, #8b5cf6)",
                        }}
                      >
                        📝
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-bold truncate">
                          {n.title || "제목 없음"}
                        </p>
                        <p
                          className="text-[11px] truncate"
                          style={{ color: "var(--text-secondary)" }}
                        >
                          {n.plain_content || "내용 없음"}
                        </p>
                      </div>
                    </Card>
                  </Link>
                ))}
              </div>
            </Section>
          )}
        </div>
      )}
    </div>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section>
      <p
        className="text-xs font-bold mb-2 px-1"
        style={{ color: "var(--text-secondary)" }}
      >
        {title}
      </p>
      {children}
    </section>
  );
}
