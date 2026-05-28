import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SettlementList } from "./settlement-list";
import { PageHeader } from "@/components/ui/page-header";
import { EmptyState } from "@/components/ui/empty-state";
import { Card } from "@/components/ui/card";
import { formatKrw } from "@/lib/format";
import type { Settlement } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function SettlementsPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const PAGE_SIZE = 100;
  const { data, count } = await supabase
    .from("settlements")
    .select("*", { count: "exact" })
    .eq("workspace_id", ctx!.workspace!.id)
    .order("created_at", { ascending: false })
    .range(0, PAGE_SIZE - 1);
  const items = (data ?? []) as Settlement[];
  const total = count ?? items.length;

  const totalNet = items
    .filter((s) => s.is_paid)
    .reduce((a, s) => a + (s.amount - s.fee - s.tax), 0);
  const pendingTotal = items
    .filter((s) => !s.is_paid)
    .reduce((a, s) => a + (s.amount - s.fee - s.tax), 0);

  return (
    <div>
      <PageHeader
        title="정산"
        subtitle={`총 ${items.length}건`}
        action={
          <div className="flex items-center gap-2">
            <Link href="/settlements/report" className="btn btn-secondary text-sm">
              월 리포트
            </Link>
            <Link href="/settlements/new" className="btn btn-primary">
              + 추가
            </Link>
          </div>
        }
      />

      <div className="grid grid-cols-2 gap-3 mb-6">
        <StatCard
          icon="✅"
          label="지급 완료 (실수령)"
          value={formatKrw(totalNet)}
          accent="linear-gradient(135deg, #10b981, #06b6d4)"
        />
        <StatCard
          icon="⏰"
          label="미지급 (실수령)"
          value={formatKrw(pendingTotal)}
          accent="linear-gradient(135deg, #f59e0b, #ec4899)"
        />
      </div>

      {items.length === 0 ? (
        <EmptyState
          emoji="💰"
          title="아직 등록된 정산이 없어요"
          description="협찬을 '완료'로 바꾸면 자동 생성되거나, 직접 추가할 수 있어요"
          action={{ label: "정산 추가", href: "/settlements/new" }}
        />
      ) : (
        <SettlementList initialItems={items} totalCount={total} pageSize={PAGE_SIZE} />
      )}
    </div>
  );
}

function StatCard({
  icon,
  label,
  value,
  accent,
}: {
  icon: string;
  label: string;
  value: string;
  accent: string;
}) {
  return (
    <Card padding="md">
      <div className="flex items-center gap-3 mb-2">
        <div
          className="w-9 h-9 rounded-xl flex items-center justify-center text-base"
          style={{ background: accent, boxShadow: "var(--shadow-sm)" }}
        >
          {icon}
        </div>
        <p className="text-[11px] font-semibold" style={{ color: "var(--text-tertiary)" }}>
          {label}
        </p>
      </div>
      <p className="text-lg lg:text-xl font-bold tabular">{value}</p>
    </Card>
  );
}
