import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SettlementForm } from "../settlement-form";
import { PageHeader } from "@/components/ui/page-header";
import type { Sponsorship } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function NewSettlementPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data } = await supabase
    .from("sponsorships")
    .select("id, brand_name, amount")
    .eq("workspace_id", ctx!.workspace!.id)
    .order("created_at", { ascending: false });

  return (
    <div>
      <PageHeader title="새 정산" subtitle="브랜드/금액/수수료/세금을 입력하세요" />
      <SettlementForm sponsorshipOptions={(data ?? []) as Pick<Sponsorship, "id" | "brand_name" | "amount">[]} />
    </div>
  );
}
