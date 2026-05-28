import type { HTMLAttributes } from "react";

type Tone = "default" | "brand" | "success" | "warning" | "danger" | "info";

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  tone?: Tone;
}

const STYLE: Record<Tone, { bg: string; fg: string }> = {
  default: { bg: "var(--muted)", fg: "var(--text-secondary)" },
  brand: { bg: "var(--brand-soft)", fg: "var(--brand)" },
  success: { bg: "var(--success-soft)", fg: "var(--success)" },
  warning: { bg: "var(--warning-soft)", fg: "var(--warning)" },
  danger: { bg: "var(--danger-soft)", fg: "var(--danger)" },
  info: { bg: "var(--info-soft)", fg: "var(--info)" },
};

export function Badge({ tone = "default", className = "", style, children, ...rest }: BadgeProps) {
  const { bg, fg } = STYLE[tone];
  return (
    <span
      className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-bold ${className}`}
      style={{ background: bg, color: fg, ...style }}
      {...rest}
    >
      {children}
    </span>
  );
}
