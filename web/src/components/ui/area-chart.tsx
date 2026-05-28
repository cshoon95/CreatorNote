"use client";

import { formatKrwShort } from "@/lib/format";

interface Point {
  label: string;
  value: number;
}

export function AreaChart({
  points,
  height = 160,
  color = "var(--brand)",
}: {
  points: Point[];
  height?: number;
  color?: string;
}) {
  if (points.length === 0) return null;
  const max = Math.max(...points.map((p) => p.value), 1);
  const w = 100;
  const h = 100;
  const step = points.length > 1 ? w / (points.length - 1) : 0;
  const coords = points.map((p, i) => {
    const x = i * step;
    const y = h - (p.value / max) * h;
    return { x, y };
  });
  const pathLine = coords.map((c, i) => `${i === 0 ? "M" : "L"} ${c.x} ${c.y}`).join(" ");
  const pathArea = pathLine + ` L ${coords[coords.length - 1].x} ${h} L 0 ${h} Z`;

  return (
    <div className="relative" style={{ height }}>
      <svg
        viewBox={`0 0 ${w} ${h}`}
        preserveAspectRatio="none"
        className="w-full h-full"
      >
        <defs>
          <linearGradient id="area-grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity="0.25" />
            <stop offset="100%" stopColor={color} stopOpacity="0" />
          </linearGradient>
        </defs>
        <path d={pathArea} fill="url(#area-grad)" />
        <path d={pathLine} fill="none" stroke={color} strokeWidth="0.7" strokeLinejoin="round" strokeLinecap="round" />
        {coords.map((c, i) => (
          <circle key={i} cx={c.x} cy={c.y} r="1.2" fill={color} />
        ))}
      </svg>
      <div className="absolute inset-x-0 bottom-0 flex justify-between text-[10px] px-1" style={{ color: "var(--text-tertiary)" }}>
        {points.map((p, i) => (
          <span key={i} className="tabular">
            {i === 0 || i === points.length - 1 || i === Math.floor(points.length / 2)
              ? p.label
              : ""}
          </span>
        ))}
      </div>
      <div className="absolute top-0 right-0 text-[10px] tabular" style={{ color: "var(--text-tertiary)" }}>
        {formatKrwShort(max)}
      </div>
    </div>
  );
}
