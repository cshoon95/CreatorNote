"use client";

import { formatKrw } from "@/lib/format";

interface Slice {
  label: string;
  value: number;
  color: string;
}

export function DonutChart({
  slices,
  centerLabel,
  centerValue,
  size = 180,
  thickness = 22,
}: {
  slices: Slice[];
  centerLabel: string;
  centerValue: string;
  size?: number;
  thickness?: number;
}) {
  const total = slices.reduce((a, s) => a + s.value, 0);
  const radius = (size - thickness) / 2;
  const circumference = 2 * Math.PI * radius;
  let offset = 0;

  return (
    <div className="flex items-center gap-5">
      <svg width={size} height={size} className="flex-shrink-0 -rotate-90">
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke="var(--muted)"
          strokeWidth={thickness}
        />
        {total > 0 &&
          slices.map((s) => {
            const len = (s.value / total) * circumference;
            const dashArray = `${len} ${circumference - len}`;
            const node = (
              <circle
                key={s.label}
                cx={size / 2}
                cy={size / 2}
                r={radius}
                fill="none"
                stroke={s.color}
                strokeWidth={thickness}
                strokeDasharray={dashArray}
                strokeDashoffset={-offset}
                strokeLinecap="butt"
              />
            );
            offset += len;
            return node;
          })}
      </svg>
      <div>
        <p
          className="text-[11px] font-semibold mb-1.5"
          style={{ color: "var(--text-tertiary)" }}
        >
          {centerLabel}
        </p>
        <p className="text-2xl font-bold tabular mb-3">{centerValue}</p>
        <ul className="space-y-1.5">
          {slices.map((s) => {
            const pct = total === 0 ? 0 : Math.round((s.value / total) * 100);
            return (
              <li key={s.label} className="flex items-center gap-2 text-xs">
                <span
                  className="w-2.5 h-2.5 rounded-sm flex-shrink-0"
                  style={{ background: s.color }}
                />
                <span style={{ color: "var(--text-secondary)" }}>{s.label}</span>
                <span className="ml-auto font-semibold tabular">
                  {formatKrw(s.value)}
                </span>
                <span
                  className="text-[10px] font-bold tabular w-9 text-right"
                  style={{ color: "var(--text-tertiary)" }}
                >
                  {pct}%
                </span>
              </li>
            );
          })}
        </ul>
      </div>
    </div>
  );
}
