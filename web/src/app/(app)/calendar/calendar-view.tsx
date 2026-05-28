"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Card } from "@/components/ui/card";
import { SponsorshipBadge } from "@/components/ui/status-badge";
import { Avatar } from "@/components/ui/avatar";
import { formatKrw, formatDate } from "@/lib/format";
import type { Sponsorship } from "@/lib/types";

const WEEKDAYS = ["일", "월", "화", "수", "목", "금", "토"];

export function CalendarView({ items }: { items: Sponsorship[] }) {
  const today = new Date();
  const [year, setYear] = useState(today.getFullYear());
  const [month, setMonth] = useState(today.getMonth());
  const [selectedDate, setSelectedDate] = useState<string | null>(null);

  const monthlyByDay = useMemo(() => {
    const map = new Map<string, Sponsorship[]>();
    for (const s of items) {
      if (!s.start_date || !s.end_date) continue;
      const start = new Date(s.start_date);
      const end = new Date(s.end_date);
      const cursor = new Date(start.getFullYear(), start.getMonth(), start.getDate());
      const last = new Date(end.getFullYear(), end.getMonth(), end.getDate());
      while (cursor <= last) {
        const key = cursor.toISOString().slice(0, 10);
        const arr = map.get(key) ?? [];
        arr.push(s);
        map.set(key, arr);
        cursor.setDate(cursor.getDate() + 1);
      }
    }
    return map;
  }, [items]);

  const firstOfMonth = new Date(year, month, 1);
  const firstWeekday = firstOfMonth.getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const cells: (Date | null)[] = [];
  for (let i = 0; i < firstWeekday; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(new Date(year, month, d));
  while (cells.length % 7 !== 0) cells.push(null);

  const navigate = (delta: number) => {
    const nm = month + delta;
    if (nm < 0) {
      setMonth(11);
      setYear((y) => y - 1);
    } else if (nm > 11) {
      setMonth(0);
      setYear((y) => y + 1);
    } else {
      setMonth(nm);
    }
    setSelectedDate(null);
  };

  const isToday = (d: Date) =>
    d.getFullYear() === today.getFullYear() &&
    d.getMonth() === today.getMonth() &&
    d.getDate() === today.getDate();

  const monthlyItems = useMemo(() => {
    const set = new Set<string>();
    const filtered: Sponsorship[] = [];
    for (const [key, arr] of monthlyByDay) {
      if (key.startsWith(`${year}-${String(month + 1).padStart(2, "0")}`)) {
        for (const s of arr) {
          if (!set.has(s.id)) {
            set.add(s.id);
            filtered.push(s);
          }
        }
      }
    }
    return filtered.sort((a, b) =>
      (a.end_date ?? "").localeCompare(b.end_date ?? ""),
    );
  }, [monthlyByDay, year, month]);

  const dayItems = selectedDate ? monthlyByDay.get(selectedDate) ?? [] : [];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_320px] gap-5">
      <Card padding="md">
        <div className="flex items-center justify-between mb-4">
          <button
            onClick={() => navigate(-1)}
            className="w-9 h-9 rounded-full flex items-center justify-center text-base hover:bg-[var(--muted)]"
            style={{ color: "var(--text-secondary)" }}
            aria-label="이전 달"
          >
            ‹
          </button>
          <h2 className="text-lg font-bold tabular">
            {year}년 {month + 1}월
          </h2>
          <button
            onClick={() => navigate(1)}
            className="w-9 h-9 rounded-full flex items-center justify-center text-base hover:bg-[var(--muted)]"
            style={{ color: "var(--text-secondary)" }}
            aria-label="다음 달"
          >
            ›
          </button>
        </div>

        <div className="grid grid-cols-7 gap-1 text-center mb-2">
          {WEEKDAYS.map((w, i) => (
            <div
              key={w}
              className="text-[11px] font-semibold py-1.5"
              style={{
                color:
                  i === 0
                    ? "var(--danger)"
                    : i === 6
                      ? "var(--info)"
                      : "var(--text-secondary)",
              }}
            >
              {w}
            </div>
          ))}
        </div>
        <div className="grid grid-cols-7 gap-1 lg:gap-1.5">
          {cells.map((d, i) => {
            if (!d) return <div key={i} />;
            const key = d.toISOString().slice(0, 10);
            const dayList = monthlyByDay.get(key) ?? [];
            const selected = selectedDate === key;
            const todayClass = isToday(d);
            return (
              <button
                key={key}
                onClick={() => setSelectedDate(selected ? null : key)}
                className="aspect-square rounded-xl p-1 flex flex-col items-center justify-start text-[11px] transition-all relative"
                style={{
                  background: selected
                    ? "var(--gradient-brand)"
                    : todayClass
                      ? "var(--brand-soft)"
                      : "transparent",
                  color: selected
                    ? "white"
                    : todayClass
                      ? "var(--brand)"
                      : "var(--text)",
                }}
              >
                <span className={`tabular ${todayClass ? "font-bold" : "font-medium"} text-xs`}>
                  {d.getDate()}
                </span>
                {dayList.length > 0 && (
                  <span
                    className="w-1.5 h-1.5 rounded-full mt-0.5"
                    style={{ background: selected ? "white" : "var(--brand)" }}
                  />
                )}
              </button>
            );
          })}
        </div>
      </Card>

      {selectedDate && dayItems.length > 0 && (
        <section className="mt-5">
          <h3 className="text-sm font-bold mb-3 px-1">{formatDate(selectedDate)}</h3>
          <div className="space-y-2">
            {dayItems.map((s) => (
              <Link key={s.id} href={`/sponsorships/${s.id}`}>
                <Card hover padding="md" className="flex items-center gap-3">
                  <Avatar name={s.brand_name} size={40} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold truncate">{s.brand_name}</p>
                    <p className="text-[11px] tabular" style={{ color: "var(--text-secondary)" }}>
                      {formatDate(s.start_date)} ~ {formatDate(s.end_date)}
                    </p>
                  </div>
                  <SponsorshipBadge status={s.status} />
                </Card>
              </Link>
            ))}
          </div>
        </section>
      )}

      {!selectedDate && monthlyItems.length > 0 && (
        <section className="mt-5">
          <h3 className="text-sm font-bold mb-3 px-1">이번 달 협찬 ({monthlyItems.length}건)</h3>
          <div className="space-y-2">
            {monthlyItems.map((s) => (
              <Link key={s.id} href={`/sponsorships/${s.id}`}>
                <Card hover padding="md" className="flex items-center gap-3">
                  <Avatar name={s.brand_name} size={40} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-bold truncate">{s.brand_name}</p>
                    <p className="text-[11px] tabular" style={{ color: "var(--text-secondary)" }}>
                      {formatDate(s.start_date)} ~ {formatDate(s.end_date)}
                    </p>
                  </div>
                  <span className="text-sm font-bold tabular text-gradient">
                    {formatKrw(s.amount)}
                  </span>
                </Card>
              </Link>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
