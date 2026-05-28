import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SponsorshipList } from "./sponsorship-list";
import { PageHeader } from "@/components/ui/page-header";
import { EmptyState } from "@/components/ui/empty-state";
import type { Sponsorship } from "@/lib/types";

export const dynamic = "force-dynamic";

const PAGE_SIZE = 100;

export default async function SponsorshipsPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data, count } = await supabase
    .from("sponsorships")
    .select("*", { count: "exact" })
    .eq("workspace_id", ctx!.workspace!.id)
    .order("is_pinned", { ascending: false })
    .order("end_date")
    .range(0, PAGE_SIZE - 1);

  const items = (data ?? []) as Sponsorship[];
  const total = count ?? items.length;

  return (
    <div>
      <PageHeader
        title="협찬"
        subtitle={`진행 중인 캠페인 ${total}건`}
        action={
          <Link href="/sponsorships/new" className="btn btn-primary">
            + 새 협찬
          </Link>
        }
      />
      {items.length === 0 ? (
        <EmptyState
          emoji="🤝"
          title="아직 등록된 협찬이 없어요"
          description="첫 협찬을 추가하고 마감일·정산을 한 번에 관리해보세요"
          action={{ label: "협찬 추가하기", href: "/sponsorships/new" }}
        />
      ) : (
        <SponsorshipList initialItems={items} totalCount={total} pageSize={PAGE_SIZE} />
      )}
    </div>
  );
}
