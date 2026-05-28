"use client";

import { useTheme, type ThemeMode } from "@/components/theme-provider";

const OPTIONS: { value: ThemeMode; label: string; emoji: string }[] = [
  { value: "system", label: "시스템", emoji: "🖥️" },
  { value: "light", label: "라이트", emoji: "☀️" },
  { value: "dark", label: "다크", emoji: "🌙" },
];

export function ThemeToggle() {
  const { mode, setMode } = useTheme();
  return (
    <div
      className="grid grid-cols-3 gap-1 p-1 rounded-xl"
      style={{ background: "var(--muted)", border: "1px solid var(--border)" }}
    >
      {OPTIONS.map((o) => {
        const active = mode === o.value;
        return (
          <button
            key={o.value}
            onClick={() => setMode(o.value)}
            className="py-2 rounded-lg text-xs font-semibold transition-all flex items-center justify-center gap-1.5"
            style={{
              background: active ? "var(--surface)" : "transparent",
              color: active ? "var(--text)" : "var(--text-secondary)",
              boxShadow: active ? "var(--shadow-sm)" : undefined,
            }}
          >
            <span>{o.emoji}</span>
            {o.label}
          </button>
        );
      })}
    </div>
  );
}
