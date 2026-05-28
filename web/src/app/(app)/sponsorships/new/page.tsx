import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SponsorshipForm } from "../sponsorship-form";
import { PageHeader } from "@/components/ui/page-header";

export const dynamic = "force-dynamic";

export default async function NewSponsorshipPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data } = await supabase
    .from("sponsorships")
    .select("brand_name")
    .eq("workspace_id", ctx!.workspace!.id);
  const brands = Array.from(
    new Set((data ?? []).map((d: { brand_name: string }) => d.brand_name)),
  );

  return (
    <div>
      <PageHeader title="새 협찬" subtitle="브랜드·제품·기간·금액을 입력하세요" />
      <SponsorshipForm brandSuggestions={brands} />
    </div>
  );
}
