import { formatKrw } from "@/lib/format";

interface BarRow {
  label: string;
  value: number;
  sub?: string;
}

export function HorizontalBars({ rows, color = "var(--brand)" }: { rows: BarRow[]; color?: string }) {
  if (rows.length === 0) return null;
  const max = Math.max(...rows.map((r) => r.value), 1);
  return (
    <ul className="space-y-2.5">
      {rows.map((r, i) => {
        const pct = (r.value / max) * 100;
        return (
          <li key={r.label + i}>
            <div className="flex items-center justify-between mb-1">
              <div className="flex items-center gap-2 min-w-0">
                <span
                  className="text-[10px] font-bold tabular w-4 text-center"
                  style={{ color: "var(--text-tertiary)" }}
                >
                  {i + 1}
                </span>
                <span className="text-xs font-semibold truncate">{r.label}</span>
                {r.sub && (
                  <span
                    className="text-[10px] tabular"
                    style={{ color: "var(--text-tertiary)" }}
                  >
                    {r.sub}
                  </span>
                )}
              </div>
              <span className="text-xs font-bold tabular">{formatKrw(r.value)}</span>
            </div>
            <div
              className="h-2 rounded-full overflow-hidden"
              style={{ background: "var(--muted)" }}
            >
              <div
                className="h-full rounded-full transition-all"
                style={{ width: `${pct}%`, background: color }}
              />
            </div>
          </li>
        );
      })}
    </ul>
  );
}
