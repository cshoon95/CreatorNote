"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { toast } from "@/components/toast";
import { formatDate } from "@/lib/format";
import type { InviteCode } from "@/lib/types";

const CHARSET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

function randomCode(): string {
  let s = "";
  const arr = new Uint32Array(6);
  crypto.getRandomValues(arr);
  for (let i = 0; i < 6; i++) s += CHARSET[arr[i] % CHARSET.length];
  return s;
}

export function InvitesClient({
  workspaceId,
  userId,
  initialCodes,
}: {
  workspaceId: string;
  userId: string;
  initialCodes: InviteCode[];
}) {
  const router = useRouter();
  const [codes, setCodes] = useState(initialCodes);
  const [busy, setBusy] = useState(false);

  const generate = async () => {
    setBusy(true);
    const supabase = createClient();
    let attempt = 0;
    while (attempt < 3) {
      const code = randomCode();
      const expiresAt = new Date(Date.now() + 7 * 86_400_000).toISOString();
      const { data, error } = await supabase
        .from("invite_codes")
        .insert({
          workspace_id: workspaceId,
          code,
          created_by: userId,
          expires_at: expiresAt,
          max_uses: 5,
          used_count: 0,
          is_active: true,
        })
        .select()
        .single();
      if (!error && data) {
        setCodes((cur) => [data as InviteCode, ...cur]);
        toast(`초대 코드 ${code} 발급됨`, "success");
        await navigator.clipboard?.writeText(code).catch(() => {});
        router.refresh();
        setBusy(false);
        return;
      }
      attempt++;
    }
    toast("초대 코드 발급에 실패했어요", "danger");
    setBusy(false);
  };

  const deactivate = async (id: string) => {
    if (!confirm("이 초대 코드를 비활성화할까요?")) return;
    const supabase = createClient();
    const { error } = await supabase.from("invite_codes").update({ is_active: false }).eq("id", id);
    if (error) {
      toast("실패: " + error.message, "danger");
    } else {
      setCodes((cur) => cur.map((c) => (c.id === id ? { ...c, is_active: false } : c)));
      toast("비활성화되었어요", "info");
    }
  };

  const copy = async (code: string) => {
    try {
      await navigator.clipboard.writeText(code);
      toast(`${code} 복사됨`, "info");
    } catch {
      toast("복사 실패 — 브라우저 권한 확인", "danger");
    }
  };

  return (
    <div>
      <button onClick={generate} disabled={busy} className="btn-primary w-full sm:w-auto">
        {busy ? "발급 중..." : "+ 새 초대 코드 발급"}
      </button>

      {codes.length === 0 ? (
        <p className="text-center text-sm mt-12" style={{ color: "var(--text-secondary)" }}>
          발급된 초대 코드가 없어요
        </p>
      ) : (
        <ul className="mt-5 space-y-2">
          {codes.map((c) => {
            const expired = c.expires_at && new Date(c.expires_at) < new Date();
            const maxedOut = c.max_uses > 0 && c.used_count >= c.max_uses;
            const usable = c.is_active && !expired && !maxedOut;
            return (
              <li key={c.id} className="card p-4">
                <div className="flex items-center justify-between gap-3">
                  <button
                    onClick={() => copy(c.code)}
                    className="text-2xl font-mono font-bold tracking-widest"
                    style={{ color: usable ? "var(--primary)" : "var(--text-tertiary)" }}
                  >
                    {c.code}
                  </button>
                  {usable ? (
                    <button onClick={() => deactivate(c.id)} className="btn-secondary text-xs px-3 py-1.5" style={{ color: "var(--danger)" }}>
                      비활성화
                    </button>
                  ) : (
                    <span className="text-xs font-semibold px-2.5 py-1 rounded-full" style={{ background: "var(--border)", color: "var(--text-tertiary)" }}>
                      {!c.is_active ? "비활성" : maxedOut ? "한도 초과" : "만료됨"}
                    </span>
                  )}
                </div>
                <p className="text-[11px] mt-2" style={{ color: "var(--text-secondary)" }}>
                  만료 {formatDate(c.expires_at)} · 사용 {c.used_count}/{c.max_uses || "∞"}
                </p>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
