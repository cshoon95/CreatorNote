"use client";

import { createContext, useContext, useEffect, useState, type ReactNode } from "react";

export type ThemeMode = "system" | "light" | "dark";

interface ThemeCtx {
  mode: ThemeMode;
  setMode: (m: ThemeMode) => void;
  effective: "light" | "dark";
}

const Ctx = createContext<ThemeCtx | null>(null);
const KEY = "influe.theme";

function resolve(mode: ThemeMode): "light" | "dark" {
  if (mode !== "system") return mode;
  if (typeof window === "undefined") return "light";
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  // Default to light — the design was built for a clean light theme. Users
  // can opt into "system" or "dark" via Settings → 테마.
  const [mode, setModeState] = useState<ThemeMode>("light");
  const [effective, setEffective] = useState<"light" | "dark">("light");

  useEffect(() => {
    const stored = (localStorage.getItem(KEY) as ThemeMode | null) ?? "light";
    setModeState(stored);
  }, []);

  useEffect(() => {
    const apply = () => {
      const eff = resolve(mode);
      setEffective(eff);
      document.documentElement.setAttribute("data-theme", eff);
    };
    apply();
    if (mode === "system") {
      const mq = window.matchMedia("(prefers-color-scheme: dark)");
      mq.addEventListener("change", apply);
      return () => mq.removeEventListener("change", apply);
    }
  }, [mode]);

  const setMode = (m: ThemeMode) => {
    localStorage.setItem(KEY, m);
    setModeState(m);
  };

  return <Ctx.Provider value={{ mode, setMode, effective }}>{children}</Ctx.Provider>;
}

export function useTheme(): ThemeCtx {
  const v = useContext(Ctx);
  if (!v) throw new Error("useTheme must be used inside ThemeProvider");
  return v;
}
