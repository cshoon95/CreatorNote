"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { toast } from "@/components/toast";
import type { MemberRole, MemberStatus, Profile } from "@/lib/types";

interface MemberEntry {
  user_id: string;
  role: MemberRole;
  status: MemberStatus;
  profile: Profile | null;
}

interface MembersClientProps {
  workspaceId: string;
  ownerId: string;
  currentUserId: string;
  isOwner: boolean;
  approved: MemberEntry[];
  pending: MemberEntry[];
}

export function MembersClient({
  workspaceId,
  ownerId,
  currentUserId,
  isOwner,
  approved,
  pending,
}: MembersClientProps) {
  const router = useRouter();
  const [busy, setBusy] = useState<string | null>(null);

  const approve = async (userId: string) => {
    setBusy(userId);
    const supabase = createClient();
    const { error } = await supabase
      .from("workspace_members")
      .update({ status: "approved" })
      .eq("workspace_id", workspaceId)
      .eq("user_id", userId);
    if (error) {
      toast("승인 실패: " + error.message, "danger");
    } else {
      toast("멤버를 승인했어요", "success");
      router.refresh();
    }
    setBusy(null);
  };

  const reject = async (userId: string) => {
    if (!confirm("이 요청을 거절하시겠어요?")) return;
    setBusy(userId);
    const supabase = createClient();
    const { error } = await supabase
      .from("workspace_members")
      .delete()
      .eq("workspace_id", workspaceId)
      .eq("user_id", userId);
    if (error) {
      toast("거절 실패", "danger");
    } else {
      toast("요청을 거절했어요", "info");
      router.refresh();
    }
    setBusy(null);
  };

  const remove = async (userId: string) => {
    if (!confirm("이 멤버를 추방하시겠어요?")) return;
    setBusy(userId);
    const supabase = createClient();
    const { error } = await supabase
      .from("workspace_members")
      .delete()
      .eq("workspace_id", workspaceId)
      .eq("user_id", userId);
    if (error) {
      toast("추방 실패", "danger");
    } else {
      toast("멤버를 추방했어요", "success");
      router.refresh();
    }
    setBusy(null);
  };

  const leave = async () => {
    if (currentUserId === ownerId) {
      toast("방장은 나갈 수 없어요. 워크스페이스를 삭제하거나 방장을 위임하세요.", "warning");
      return;
    }
    if (!confirm("이 워크스페이스를 나가시겠어요?")) return;
    const supabase = createClient();
    const { error } = await supabase
      .from("workspace_members")
      .delete()
      .eq("workspace_id", workspaceId)
      .eq("user_id", currentUserId);
    if (error) {
      toast("나가기 실패", "danger");
    } else {
      toast("워크스페이스에서 나왔어요", "info");
      router.push("/onboarding");
      router.refresh();
    }
  };

  return (
    <div className="space-y-6">
      {isOwner && pending.length > 0 && (
        <section>
          <h3 className="text-xs font-bold mb-2 px-1" style={{ color: "var(--warning)" }}>
            승인 대기 · {pending.length}
          </h3>
          <ul className="space-y-2">
            {pending.map((m) => (
              <li key={m.user_id} className="card p-3 flex items-center gap-3">
                <MemberAvatar profile={m.profile} />
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-bold truncate">{m.profile?.display_name ?? "이름 미설정"}</p>
                  <p className="text-[11px]" style={{ color: "var(--text-secondary)" }}>참여 요청</p>
                </div>
                <button onClick={() => approve(m.user_id)} disabled={busy === m.user_id} className="btn-primary text-xs px-3 py-1.5">
                  승인
                </button>
                <button onClick={() => reject(m.user_id)} disabled={busy === m.user_id} className="btn-secondary text-xs px-3 py-1.5" style={{ color: "var(--danger)" }}>
                  거절
                </button>
              </li>
            ))}
          </ul>
        </section>
      )}

      <section>
        <h3 className="text-xs font-bold mb-2 px-1" style={{ color: "var(--text-secondary)" }}>
          멤버 · {approved.length}
        </h3>
        <ul className="space-y-2">
          {approved.map((m) => {
            const isCurrentOwner = m.user_id === ownerId;
            return (
              <li key={m.user_id} className="card p-3 flex items-center gap-3">
                <MemberAvatar profile={m.profile} />
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-bold truncate">{m.profile?.display_name ?? "이름 미설정"}</p>
                    {isCurrentOwner && (
                      <span className="text-[10px] px-1.5 py-0.5 rounded-full font-bold" style={{ background: "var(--primary-soft)", color: "var(--primary)" }}>
                        방장
                      </span>
                    )}
                    {m.user_id === currentUserId && !isCurrentOwner && (
                      <span className="text-[10px]" style={{ color: "var(--text-tertiary)" }}>나</span>
                    )}
                  </div>
                </div>
                {isOwner && !isCurrentOwner && (
                  <button onClick={() => remove(m.user_id)} disabled={busy === m.user_id} className="btn-secondary text-xs px-3 py-1.5" style={{ color: "var(--danger)" }}>
                    추방
                  </button>
                )}
              </li>
            );
          })}
        </ul>
      </section>

      {!isOwner && (
        <button onClick={leave} className="btn-secondary w-full" style={{ color: "var(--danger)" }}>
          워크스페이스 나가기
        </button>
      )}
    </div>
  );
}

function MemberAvatar({ profile }: { profile: Profile | null }) {
  if (profile?.avatar_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={profile.avatar_url} alt="" className="w-10 h-10 rounded-full object-cover" />;
  }
  return (
    <div
      className="w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold text-white"
      style={{ background: "linear-gradient(135deg, var(--primary), var(--accent))" }}
    >
      {(profile?.display_name ?? "?").slice(0, 1)}
    </div>
  );
}
