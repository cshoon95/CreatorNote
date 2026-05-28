import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { formatKrw, formatDate } from "@/lib/format";
import { DetailActions } from "./detail-actions";
import type { Settlement } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function SettlementDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data } = await supabase
    .from("settlements")
    .select("*")
    .eq("workspace_id", ctx!.workspace!.id)
    .eq("id", id)
    .maybeSingle();
  if (!data) notFound();
  const s = data as Settlement;
  const net = s.amount - s.fee - s.tax;

  return (
    <div>
      <Link href="/settlements" className="text-sm" style={{ color: "var(--text-secondary)" }}>
        ← 정산 목록
      </Link>
      <Card padding="lg" className="mt-4 fadein">
        <div className="flex items-start justify-between">
          <div className="flex-1 min-w-0">
            <h1 className="text-xl font-bold truncate">{s.brand_name}</h1>
            <p className="text-xs mt-1" style={{ color: "var(--text-secondary)" }}>
              {formatDate(s.settlement_date)} 정산
            </p>
          </div>
          <Badge tone={s.is_paid ? "success" : "warning"}>
            {s.is_paid ? "지급 완료" : "미지급"}
          </Badge>
        </div>
        <div
          className="rounded-2xl p-5 mt-6 relative overflow-hidden"
          style={{ background: "var(--gradient-brand-soft)" }}
        >
          <p className="text-xs font-semibold" style={{ color: "var(--text-secondary)" }}>
            실수령액
          </p>
          <p className="text-3xl font-bold mt-1 tabular text-gradient">{formatKrw(net)}</p>
        </div>
        <div className="grid grid-cols-3 gap-4 mt-5">
          <Field label="총 금액" value={formatKrw(s.amount)} />
          <Field label="수수료" value={formatKrw(s.fee)} />
          <Field label="세금" value={formatKrw(s.tax)} />
        </div>
        {s.memo && (
          <div className="mt-6 pt-6 border-t" style={{ borderColor: "var(--border)" }}>
            <p className="text-xs font-semibold mb-2" style={{ color: "var(--text-secondary)" }}>
              메모
            </p>
            <p className="text-sm whitespace-pre-wrap leading-relaxed">{s.memo}</p>
          </div>
        )}
      </Card>
      <DetailActions id={s.id} brandName={s.brand_name} />
    </div>
  );
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[11px] font-semibold mb-1" style={{ color: "var(--text-secondary)" }}>
        {label}
      </p>
      <p className="text-sm font-bold tabular">{value}</p>
    </div>
  );
}
