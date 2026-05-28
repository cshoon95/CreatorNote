import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SettlementForm } from "../../settlement-form";
import { PageHeader } from "@/components/ui/page-header";
import type { Settlement, Sponsorship } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function EditSettlementPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const [{ data: settle }, { data: sponsors }] = await Promise.all([
    supabase
      .from("settlements")
      .select("*")
      .eq("workspace_id", ctx!.workspace!.id)
      .eq("id", id)
      .maybeSingle(),
    supabase
      .from("sponsorships")
      .select("id, brand_name, amount")
      .eq("workspace_id", ctx!.workspace!.id)
      .order("created_at", { ascending: false }),
  ]);
  if (!settle) notFound();
  return (
    <div>
      <PageHeader title="정산 수정" />
      <SettlementForm
        initial={settle as Settlement}
        sponsorshipOptions={(sponsors ?? []) as Pick<Sponsorship, "id" | "brand_name" | "amount">[]}
      />
    </div>
  );
}
