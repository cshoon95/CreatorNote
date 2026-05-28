import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { PageHeader } from "@/components/ui/page-header";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { ThemeToggle } from "@/components/ui/theme-toggle";
import { SignOutButton } from "./sign-out-button";
import { ProfileEditor } from "./profile-editor";
import { SettingsClient } from "./settings-client";
import type { MemberRole, MemberStatus, Profile, InviteCode } from "@/lib/types";

export const dynamic = "force-dynamic";

interface MemberRow {
  user_id: string;
  role: MemberRole;
  status: MemberStatus;
}

export default async function SettingsPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const wid = ctx!.workspace!.id;
  const isOwner = ctx!.workspace!.owner_id === ctx!.userId;

  // Fetch members with profiles
  const { data: membersRows } = await supabase
    .from("workspace_members")
    .select("user_id, role, status")
    .eq("workspace_id", wid);

  const rows = (membersRows ?? []) as MemberRow[];
  const ids = rows.map((r) => r.user_id);
  let profilesById = new Map<string, Profile>();
  if (ids.length > 0) {
    const { data: profiles } = await supabase.from("profiles").select("*").in("id", ids);
    profilesById = new Map((profiles ?? []).map((p) => [p.id, p as Profile]));
  }

  const enriched = rows.map((r) => ({
    ...r,
    profile: profilesById.get(r.user_id) ?? null,
  }));
  const approvedMembers = enriched.filter((m) => m.status === "approved");
  const pendingMembers = enriched.filter((m) => m.status === "pending");

  // Fetch invite codes (owner only)
  let inviteCodes: InviteCode[] = [];
  if (isOwner) {
    const { data } = await supabase
      .from("invite_codes")
      .select("*")
      .eq("workspace_id", wid)
      .order("created_at", { ascending: false });
    inviteCodes = (data ?? []) as InviteCode[];
  }

  return (
    <div className="max-w-2xl">
      <PageHeader title="설정" />

      <Card padding="lg">
        <h2 className="text-sm font-bold mb-4">프로필</h2>
        <ProfileEditor
          userId={ctx!.userId}
          email={ctx!.email}
          displayName={ctx!.profile?.display_name ?? ""}
          avatarUrl={ctx!.profile?.avatar_url ?? null}
        />
      </Card>

      <Card padding="lg" className="mt-4">
        <h2 className="text-sm font-bold mb-4">테마</h2>
        <ThemeToggle />
        <p className="text-[11px] mt-3" style={{ color: "var(--text-tertiary)" }}>
          시스템: OS 설정을 따릅니다. 라이트/다크: 직접 선택.
        </p>
      </Card>

      <Card padding="lg" className="mt-4">
        <h2 className="text-sm font-bold mb-4">워크스페이스</h2>
        <Row label="이름" value={ctx!.workspace!.name} />
        <Row
          label="역할"
          value={
            isOwner ? (
              <Badge tone="brand">방장 (Owner)</Badge>
            ) : (
              <span>멤버</span>
            )
          }
        />
        <Row label="승인된 멤버" value={`${approvedMembers.length}명`} />
        {isOwner && pendingMembers.length > 0 && (
          <Row
            label="승인 대기"
            value={<Badge tone="warning">{pendingMembers.length}건</Badge>}
          />
        )}
        <SettingsClient
          workspaceId={wid}
          ownerId={ctx!.workspace!.owner_id}
          currentUserId={ctx!.userId}
          isOwner={isOwner}
          approvedMembers={approvedMembers}
          pendingMembers={pendingMembers}
          inviteCodes={inviteCodes}
        />
      </Card>

      <Card padding="lg" className="mt-4">
        <h2 className="text-sm font-bold mb-3">키보드 단축키 (PC)</h2>
        <ul className="space-y-2 text-xs" style={{ color: "var(--text-secondary)" }}>
          <Shortcut keys={["Cmd", "K"]} desc="전역 검색 팔레트" />
          <Shortcut keys={["/"]} desc="검색 팔레트" />
          <Shortcut keys={["n"]} desc="현재 페이지에서 새 항목" />
          <Shortcut keys={["g", "h"]} desc="홈으로" />
          <Shortcut keys={["g", "s"]} desc="협찬 목록" />
          <Shortcut keys={["g", "m"]} desc="정산 목록" />
          <Shortcut keys={["g", "n"]} desc="노트" />
          <Shortcut keys={["g", "c"]} desc="캘린더" />
          <Shortcut keys={["g", "r"]} desc="월 리포트" />
          <Shortcut keys={["?"]} desc="도움말" />
        </ul>
      </Card>

      <div className="mt-8 text-center">
        <SignOutButton />
        <p className="text-[11px] mt-4" style={{ color: "var(--text-tertiary)" }}>
          Influe Web · {ctx!.email}
        </p>
      </div>
    </div>
  );
}

function Row({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div
      className="flex items-center justify-between py-2.5 border-b last:border-b-0"
      style={{ borderColor: "var(--border)" }}
    >
      <span className="text-xs" style={{ color: "var(--text-secondary)" }}>
        {label}
      </span>
      <span className="text-sm font-semibold text-right">{value}</span>
    </div>
  );
}

function Shortcut({ keys, desc }: { keys: string[]; desc: string }) {
  return (
    <li className="flex items-center justify-between">
      <span>{desc}</span>
      <span className="flex items-center gap-1">
        {keys.map((k, i) => (
          <kbd
            key={i}
            className="font-mono text-[10px] px-1.5 py-0.5 rounded"
            style={{
              background: "var(--muted)",
              color: "var(--text)",
              border: "1px solid var(--border)",
            }}
          >
            {k}
          </kbd>
        ))}
      </span>
    </li>
  );
}
