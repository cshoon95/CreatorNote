import { redirect } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { PageHeader } from "@/components/ui/page-header";
import { InvitesClient } from "./invites-client";
import type { InviteCode } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function InvitesPage() {
  const ctx = await getAuthContext();
  if (ctx!.workspace!.owner_id !== ctx!.userId) redirect("/settings");

  const supabase = await createClient();
  const { data } = await supabase
    .from("invite_codes")
    .select("*")
    .eq("workspace_id", ctx!.workspace!.id)
    .order("created_at", { ascending: false });

  return (
    <div className="max-w-2xl">
      <Link href="/settings" className="text-sm" style={{ color: "var(--text-secondary)" }}>
        ← 설정
      </Link>
      <PageHeader title="초대 코드" subtitle="새 멤버를 초대할 수 있는 6자리 코드를 발급해요" />
      <InvitesClient workspaceId={ctx!.workspace!.id} userId={ctx!.userId} initialCodes={(data ?? []) as InviteCode[]} />
    </div>
  );
}
