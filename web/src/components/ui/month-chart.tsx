"use client";

import { Card } from "./card";
import { formatKrwShort, formatKrw } from "@/lib/format";

export interface MonthDatum {
  key: string; // YYYY-MM
  label: string;
  paid: number;
  unpaid: number;
}

export function MonthChart({ data }: { data: MonthDatum[] }) {
  if (data.length === 0) return null;
  const max = Math.max(...data.map((d) => d.paid + d.unpaid), 1);
  const currentMonthKey = new Date().toISOString().slice(0, 7);

  return (
    <Card padding="lg" className="overflow-hidden">
      <div className="flex items-center justify-between mb-5">
        <div>
          <p className="text-sm font-bold">최근 6개월 수익</p>
          <p className="text-[11px] mt-0.5" style={{ color: "var(--text-tertiary)" }}>
            지급 완료 (실수령) · 미지급
          </p>
        </div>
        <div className="flex items-center gap-3 text-[11px]">
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full" style={{ background: "var(--success)" }} />
            지급
          </span>
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full" style={{ background: "var(--warning)" }} />
            미지급
          </span>
        </div>
      </div>

      <div className="grid grid-cols-6 gap-2" style={{ height: 200 }}>
        {data.map((d) => {
          const total = d.paid + d.unpaid;
          const heightPct = (total / max) * 100;
          const paidPct = total === 0 ? 0 : (d.paid / total) * 100;
          const unpaidPct = 100 - paidPct;
          const isCurrent = d.key === currentMonthKey;
          return (
            <div key={d.key} className="flex flex-col items-center h-full group">
              <div
                className="h-4 text-[10px] font-bold tabular opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap"
                style={{ color: "var(--text)" }}
              >
                {total > 0 ? formatKrwShort(total) : ""}
              </div>

              <div className="flex-1 w-full flex flex-col justify-end">
                {total === 0 ? (
                  <div
                    className="w-full rounded-md"
                    style={{
                      height: 6,
                      background: "var(--muted)",
                      border: "1px dashed var(--border)",
                    }}
                  />
                ) : (
                  <div
                    className="w-full rounded-lg overflow-hidden flex flex-col-reverse relative"
                    style={{
                      height: `${Math.max(heightPct, 8)}%`,
                      border: isCurrent
                        ? "2px solid var(--brand)"
                        : "1px solid var(--border)",
                    }}
                    title={`${d.label}\n지급 ${formatKrw(d.paid)}\n미지급 ${formatKrw(d.unpaid)}`}
                  >
                    {d.paid > 0 && (
                      <div
                        style={{
                          height: `${paidPct}%`,
                          background: "var(--success)",
                        }}
                      />
                    )}
                    {d.unpaid > 0 && (
                      <div
                        style={{
                          height: `${unpaidPct}%`,
                          background: "var(--warning)",
                        }}
                      />
                    )}
                  </div>
                )}
              </div>

              <div
                className="mt-1.5 text-[10px] text-center"
                style={{
                  color: isCurrent ? "var(--brand)" : "var(--text-tertiary)",
                }}
              >
                <p className="font-bold">{d.label.split(" ")[1]}</p>
              </div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}
