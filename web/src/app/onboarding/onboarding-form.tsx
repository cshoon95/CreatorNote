"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";

type Mode = "create" | "join";

export function OnboardingForm({ displayName }: { displayName: string | null }) {
  const router = useRouter();
  const [mode, setMode] = useState<Mode>("create");
  const [name, setName] = useState(displayName ? `${displayName}의 워크스페이스` : "");
  const [code, setCode] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const createWorkspace = async () => {
    if (!name.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();
      // Atomic RPC: creates workspace + owner membership in single transaction.
      const { error: rpcErr } = await supabase.rpc("create_workspace_with_owner", {
        ws_name: name.trim(),
      });
      if (rpcErr) {
        setError(rpcErr.message);
        return;
      }
      toast("✨ 워크스페이스가 생성되었어요", "success");
      router.push("/dashboard");
      router.refresh();
    } finally {
      setLoading(false);
    }
  };

  const joinWorkspace = async () => {
    if (!code.trim()) return;
    setLoading(true);
    setError(null);
    try {
      const supabase = createClient();
      // Atomic RPC: validates code + checks expiry/max_uses + inserts membership
      // + increments used_count, all in single transaction.
      const { error: rpcErr } = await supabase.rpc("redeem_invite", {
        invite_code: code.trim().toUpperCase(),
      });
      if (rpcErr) {
        // Translate common server messages
        const msg = rpcErr.message ?? "";
        if (msg.includes("Invalid")) setError("유효하지 않은 초대 코드입니다");
        else if (msg.includes("expired")) setError("만료된 초대 코드입니다");
        else if (msg.includes("maximum")) setError("초대 코드 사용 한도에 도달했어요");
        else setError(msg || "참여 실패");
        return;
      }
      toast("📨 참여 요청을 보냈어요", "info");
      router.push("/pending");
      router.refresh();
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <div
        className="grid grid-cols-2 gap-1 mb-6 p-1 rounded-2xl"
        style={{ background: "var(--muted)", border: "1px solid var(--border)" }}
      >
        <button
          onClick={() => setMode("create")}
          className="py-2.5 rounded-xl text-sm font-semibold transition-all"
          style={{
            background: mode === "create" ? "var(--surface)" : "transparent",
            color: mode === "create" ? "var(--text)" : "var(--text-secondary)",
            boxShadow: mode === "create" ? "var(--shadow-sm)" : undefined,
          }}
        >
          새로 만들기
        </button>
        <button
          onClick={() => setMode("join")}
          className="py-2.5 rounded-xl text-sm font-semibold transition-all"
          style={{
            background: mode === "join" ? "var(--surface)" : "transparent",
            color: mode === "join" ? "var(--text)" : "var(--text-secondary)",
            boxShadow: mode === "join" ? "var(--shadow-sm)" : undefined,
          }}
        >
          초대 코드로 참여
        </button>
      </div>

      <Card padding="lg">
        {mode === "create" ? (
          <div>
            <label className="label">워크스페이스 이름</label>
            <input
              className="input"
              placeholder="예: 나의 협찬 노트"
              value={name}
              onChange={(e) => setName(e.target.value)}
              maxLength={40}
              autoFocus
            />
            <p className="text-xs mt-2" style={{ color: "var(--text-tertiary)" }}>
              만든 후 멤버를 초대할 수 있어요
            </p>
            <Button
              variant="primary"
              fullWidth
              onClick={createWorkspace}
              disabled={!name.trim()}
              loading={loading}
              className="mt-5"
            >
              워크스페이스 만들기
            </Button>
          </div>
        ) : (
          <div>
            <label className="label">초대 코드 (6자리)</label>
            <input
              className="input uppercase tracking-widest text-center font-mono text-lg"
              placeholder="ABC123"
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase().slice(0, 6))}
              maxLength={6}
              autoFocus
            />
            <p className="text-xs mt-2" style={{ color: "var(--text-tertiary)" }}>
              참여 후 방장의 승인이 필요해요
            </p>
            <Button
              variant="primary"
              fullWidth
              onClick={joinWorkspace}
              disabled={code.trim().length !== 6}
              loading={loading}
              className="mt-5"
            >
              참여 요청 보내기
            </Button>
          </div>
        )}
        {error && (
          <p className="text-xs text-center mt-3" style={{ color: "var(--danger)" }}>
            {error}
          </p>
        )}
      </Card>

      <SignOutLink />
    </div>
  );
}

function SignOutLink() {
  const router = useRouter();
  const signOut = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  };
  return (
    <button
      onClick={signOut}
      className="block mx-auto mt-6 text-xs"
      style={{ color: "var(--text-tertiary)" }}
    >
      다른 계정으로 로그인
    </button>
  );
}
