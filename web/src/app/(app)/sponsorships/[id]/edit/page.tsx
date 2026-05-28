import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SponsorshipForm } from "../../sponsorship-form";
import { PageHeader } from "@/components/ui/page-header";
import type { Sponsorship } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function EditSponsorshipPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const [{ data: item }, { data: all }] = await Promise.all([
    supabase
      .from("sponsorships")
      .select("*")
      .eq("workspace_id", ctx!.workspace!.id)
      .eq("id", id)
      .maybeSingle(),
    supabase
      .from("sponsorships")
      .select("brand_name")
      .eq("workspace_id", ctx!.workspace!.id),
  ]);
  if (!item) notFound();
  const brands = Array.from(
    new Set((all ?? []).map((d: { brand_name: string }) => d.brand_name)),
  );
  return (
    <div>
      <PageHeader title="협찬 수정" />
      <SponsorshipForm initial={item as Sponsorship} brandSuggestions={brands} />
    </div>
  );
}
