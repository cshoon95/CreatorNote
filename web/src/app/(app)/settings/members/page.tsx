import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { PageHeader } from "@/components/ui/page-header";
import { MembersClient } from "./members-client";
import type { MemberRole, MemberStatus, Profile } from "@/lib/types";

export const dynamic = "force-dynamic";

interface MemberRow {
  user_id: string;
  role: MemberRole;
  status: MemberStatus;
}

export default async function MembersPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const wid = ctx!.workspace!.id;

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
  const approved = enriched.filter((m) => m.status === "approved");
  const pending = enriched.filter((m) => m.status === "pending");
  const isOwner = ctx!.workspace!.owner_id === ctx!.userId;

  return (
    <div className="max-w-2xl">
      <Link href="/settings" className="text-sm" style={{ color: "var(--text-secondary)" }}>
        ← 설정
      </Link>
      <PageHeader title="멤버" subtitle={`${ctx!.workspace!.name}`} />
      <MembersClient
        workspaceId={wid}
        ownerId={ctx!.workspace!.owner_id}
        currentUserId={ctx!.userId}
        isOwner={isOwner}
        approved={approved}
        pending={pending}
      />
    </div>
  );
}
