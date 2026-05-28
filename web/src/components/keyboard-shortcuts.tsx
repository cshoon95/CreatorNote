"use client";

import { useEffect } from "react";
import { usePathname, useRouter } from "next/navigation";

/**
 * Global keyboard shortcuts:
 *   n         — 새 항목 (현재 페이지 컨텍스트에 맞춰 라우팅)
 *   g h/s/$/n/c — 점프 (g 누르고 다음 키)
 *   ?         — 도움말 (단축키 안내)
 * Skipped when typing in input/textarea/contenteditable.
 */
export function KeyboardShortcuts() {
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    let waitingForG = false;
    let gTimer: ReturnType<typeof setTimeout> | null = null;

    const isInField = (e: KeyboardEvent) => {
      const el = e.target as HTMLElement;
      if (!el) return false;
      const tag = el.tagName;
      return (
        tag === "INPUT" ||
        tag === "TEXTAREA" ||
        tag === "SELECT" ||
        el.isContentEditable
      );
    };

    const handler = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      if (isInField(e)) return;

      // g + x — jump shortcuts
      if (waitingForG) {
        if (gTimer) {
          clearTimeout(gTimer);
          gTimer = null;
        }
        waitingForG = false;
        const map: Record<string, string> = {
          h: "/dashboard",
          d: "/dashboard",
          s: "/sponsorships",
          m: "/settlements",
          $: "/settlements",
          n: "/notes",
          c: "/calendar",
          r: "/settlements/report",
        };
        const dest = map[e.key.toLowerCase()];
        if (dest) {
          e.preventDefault();
          router.push(dest);
        }
        return;
      }

      if (e.key === "g") {
        waitingForG = true;
        gTimer = setTimeout(() => {
          waitingForG = false;
        }, 800);
        return;
      }

      if (e.key === "n") {
        const map: Record<string, string> = {
          "/sponsorships": "/sponsorships/new",
          "/settlements": "/settlements/new",
          "/notes": "/notes/reels/new",
        };
        const dest = map[pathname];
        if (dest) {
          e.preventDefault();
          router.push(dest);
        } else {
          e.preventDefault();
          router.push("/sponsorships/new");
        }
      }

      if (e.key === "?") {
        e.preventDefault();
        alert(
          [
            "⌨️ 단축키",
            "",
            "⌘K · / : 검색 팔레트",
            "n : 새 항목 (현재 페이지 기준)",
            "g h : 홈으로",
            "g s : 협찬 목록",
            "g m : 정산 목록",
            "g n : 노트",
            "g c : 캘린더",
            "g r : 월 리포트",
            "? : 이 도움말",
          ].join("\n"),
        );
      }
    };

    document.addEventListener("keydown", handler);
    return () => {
      if (gTimer) clearTimeout(gTimer);
      document.removeEventListener("keydown", handler);
    };
  }, [router, pathname]);

  return null;
}
