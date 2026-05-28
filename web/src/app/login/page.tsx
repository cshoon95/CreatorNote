"use client";

import { useEffect, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

function LoginInner() {
  const router = useRouter();
  const search = useSearchParams();
  const next = search.get("next") ?? "/";
  const oauthErr = search.get("error");
  const [checking, setChecking] = useState(true);
  const [alreadySignedIn, setAlreadySignedIn] = useState(false);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const supabase = createClient();
        const { data } = await supabase.auth.getSession();
        if (cancelled) return;
        if (data.session) {
          setAlreadySignedIn(true);
          router.replace(next);
        }
      } finally {
        if (!cancelled) setChecking(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [next, router]);

  return (
    <main
      className="min-h-screen flex items-center justify-center px-6 py-12"
      style={{ background: "var(--bg)" }}
    >
      <div className="w-full max-w-md fadein">
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center mb-6">
            <Logo size={72} />
          </div>
          <h1 className="text-3xl font-bold tracking-tight">Influe</h1>
          <p className="text-sm mt-2" style={{ color: "var(--text-secondary)" }}>
            크리에이터를 위한 협찬·정산·노트 매니저
          </p>
        </div>

        <div
          className="card p-7"
          style={{ boxShadow: "var(--shadow-lg)" }}
        >
          {alreadySignedIn ? (
            <div className="text-center py-2">
              <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
                이미 로그인되어 있어요. 이동 중...
              </p>
            </div>
          ) : (
            <>
              <form action="/auth/start" method="GET">
                <input type="hidden" name="provider" value="google" />
                <input type="hidden" name="next" value={next} />
                <button
                  type="submit"
                  disabled={checking}
                  className="w-full py-3 rounded-xl text-sm font-semibold flex items-center justify-center gap-3 transition-all hover:shadow-md active:scale-[0.99] disabled:opacity-50"
                  style={{
                    background: "white",
                    color: "#1f2937",
                    border: "1px solid var(--border-strong)",
                  }}
                >
                  <GoogleIcon />
                  Google로 계속하기
                </button>
              </form>

              <div className="mt-6 grid grid-cols-3 gap-2 text-center">
                <Feature emoji="📊" label="협찬 관리" />
                <Feature emoji="💰" label="자동 정산" />
                <Feature emoji="📝" label="릴스 노트" />
              </div>
            </>
          )}

          {oauthErr && (
            <p className="text-xs text-center mt-5" style={{ color: "var(--danger)" }}>
              로그인 오류: {oauthErr}
            </p>
          )}
        </div>

        <p
          className="text-[11px] text-center mt-8 leading-relaxed"
          style={{ color: "var(--text-tertiary)" }}
        >
          계속 진행하면 <a className="underline">서비스 이용약관</a>과{" "}
          <a className="underline">개인정보 처리방침</a>에<br /> 동의하는 것으로 간주됩니다.
        </p>
      </div>
    </main>
  );
}

function Feature({ emoji, label }: { emoji: string; label: string }) {
  return (
    <div
      className="py-3 rounded-xl"
      style={{ background: "var(--brand-soft)" }}
    >
      <div className="text-xl mb-0.5">{emoji}</div>
      <p
        className="text-[11px] font-semibold"
        style={{ color: "var(--brand)" }}
      >
        {label}
      </p>
    </div>
  );
}

function Logo({ size }: { size: number }) {
  return (
    <div
      className="rounded-2xl flex items-center justify-center"
      style={{
        width: size,
        height: size,
        background: "var(--brand)",
        boxShadow: "var(--shadow-lg)",
      }}
    >
      <span
        className="font-bold text-white"
        style={{ fontSize: size * 0.46 }}
      >
        I
      </span>
    </div>
  );
}

function GoogleIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" aria-hidden>
      <path
        fill="#4285F4"
        d="M16.51 8.18c0-.59-.05-1.16-.15-1.7H9v3.21h4.21c-.18.96-.74 1.77-1.58 2.31v1.92h2.55c1.5-1.38 2.33-3.42 2.33-5.74z"
      />
      <path
        fill="#34A853"
        d="M9 16.5c2.16 0 3.97-.71 5.29-1.94l-2.55-1.92c-.71.48-1.61.77-2.74.77-2.1 0-3.88-1.42-4.52-3.32H1.86v2.08C3.17 14.74 5.87 16.5 9 16.5z"
      />
      <path
        fill="#FBBC05"
        d="M4.48 10.09a4.51 4.51 0 0 1 0-2.69V5.32H1.86a7.5 7.5 0 0 0 0 6.85l2.62-2.08z"
      />
      <path
        fill="#EA4335"
        d="M9 4.08c1.18 0 2.24.41 3.07 1.21l2.27-2.27C12.97 1.75 11.16 1 9 1 5.87 1 3.17 2.76 1.86 5.32l2.62 2.08C5.12 5.5 6.9 4.08 9 4.08z"
      />
    </svg>
  );
}

export default function LoginPage() {
  return (
    <Suspense fallback={null}>
      <LoginInner />
    </Suspense>
  );
}
