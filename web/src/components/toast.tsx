"use client";

import { useEffect, useState } from "react";

type ToastTone = "info" | "success" | "danger" | "warning";

interface ToastAction {
  label: string;
  onClick: () => void;
}

interface ToastMessage {
  id: number;
  text: string;
  tone: ToastTone;
  action?: ToastAction;
  duration: number;
}

let counter = 0;
const listeners = new Set<(t: ToastMessage) => void>();

export function toast(
  text: string,
  toneOrOpts?: ToastTone | { tone?: ToastTone; action?: ToastAction; duration?: number },
) {
  const opts =
    typeof toneOrOpts === "string" || toneOrOpts === undefined
      ? { tone: (toneOrOpts as ToastTone) ?? "info" }
      : toneOrOpts;
  const msg: ToastMessage = {
    id: ++counter,
    text,
    tone: opts.tone ?? "info",
    action: opts.action,
    duration: opts.duration ?? (opts.action ? 5000 : 3000),
  };
  listeners.forEach((fn) => fn(msg));
}

export function ToastHost() {
  const [items, setItems] = useState<ToastMessage[]>([]);

  useEffect(() => {
    const handler = (m: ToastMessage) => {
      setItems((cur) => [...cur, m]);
      setTimeout(() => setItems((cur) => cur.filter((c) => c.id !== m.id)), m.duration);
    };
    listeners.add(handler);
    return () => {
      listeners.delete(handler);
    };
  }, []);

  return (
    <div className="fixed bottom-24 lg:bottom-6 left-1/2 -translate-x-1/2 z-[200] flex flex-col gap-2 pointer-events-none">
      {items.map((t) => (
        <div
          key={t.id}
          className="fadein px-4 py-2.5 rounded-xl text-sm font-medium shadow-lg pointer-events-auto max-w-[88vw] flex items-center gap-3"
          style={{ background: toneBg(t.tone), color: "white" }}
        >
          <span>{t.text}</span>
          {t.action && (
            <button
              onClick={() => {
                t.action!.onClick();
                setItems((cur) => cur.filter((c) => c.id !== t.id));
              }}
              className="text-xs font-bold px-2 py-0.5 rounded bg-white/20 hover:bg-white/30 transition-colors"
            >
              {t.action.label}
            </button>
          )}
        </div>
      ))}
    </div>
  );
}

function toneBg(t: ToastTone): string {
  switch (t) {
    case "success":
      return "#16a34a";
    case "danger":
      return "#dc2626";
    case "warning":
      return "#d97706";
    default:
      return "#1f2937";
  }
}
