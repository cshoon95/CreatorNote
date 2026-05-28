import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { PageHeader } from "@/components/ui/page-header";
import { Card } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { DonutChart } from "@/components/ui/donut-chart";
import { HorizontalBars } from "@/components/ui/horizontal-bar";
import { AreaChart } from "@/components/ui/area-chart";
import { formatKrw, formatKrwShort } from "@/lib/format";
import { ReportExportButton } from "./report-export-button";
import type { Settlement } from "@/lib/types";

export const dynamic = "force-dynamic";

interface MonthBucket {
  key: string;
  label: string;
  shortLabel: string;
  paid: number;
  unpaid: number;
  count: number;
}

export default async function SettlementReportPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data } = await supabase
    .from("settlements")
    .select("*")
    .eq("workspace_id", ctx!.workspace!.id)
    .order("settlement_date", { ascending: false });
  const items = (data ?? []) as Settlement[];

  if (items.length === 0) {
    return (
      <div>
        <PageHeader title="월 리포트" />
        <EmptyState
          emoji="📊"
          title="아직 데이터가 없어요"
          description="정산을 등록하면 월별 리포트가 표시됩니다"
        />
      </div>
    );
  }

  // ---- Aggregations ----
  const buckets = new Map<string, MonthBucket>();
  // Pre-populate last 12 months for area chart continuity
  const now = new Date();
  for (let i = 11; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    buckets.set(key, {
      key,
      label: `${d.getFullYear()}년 ${d.getMonth() + 1}월`,
      shortLabel: `${d.getMonth() + 1}월`,
      paid: 0,
      unpaid: 0,
      count: 0,
    });
  }

  for (const s of items) {
    const d = s.settlement_date ? new Date(s.settlement_date) : new Date(s.created_at);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    const net = s.amount - s.fee - s.tax;
    const cur =
      buckets.get(key) ?? {
        key,
        label: `${d.getFullYear()}년 ${d.getMonth() + 1}월`,
        shortLabel: `${d.getMonth() + 1}월`,
        paid: 0,
        unpaid: 0,
        count: 0,
      };
    if (s.is_paid) cur.paid += net;
    else cur.unpaid += net;
    cur.count += 1;
    buckets.set(key, cur);
  }

  const allMonths = [...buckets.values()].sort((a, b) => a.key.localeCompare(b.key));
  const last12Months = allMonths.slice(-12);
  const monthsWithData = allMonths.filter((m) => m.count > 0).reverse();

  const totalPaid = allMonths.reduce((a, b) => a + b.paid, 0);
  const totalUnpaid = allMonths.reduce((a, b) => a + b.unpaid, 0);
  const grandTotal = totalPaid + totalUnpaid;

  // Brand contribution (top 5 by net amount)
  const brandMap = new Map<string, { value: number; count: number }>();
  for (const s of items) {
    const net = s.amount - s.fee - s.tax;
    const cur = brandMap.get(s.brand_name) ?? { value: 0, count: 0 };
    cur.value += net;
    cur.count += 1;
    brandMap.set(s.brand_name, cur);
  }
  const topBrands = [...brandMap.entries()]
    .map(([label, v]) => ({ label, value: v.value, sub: `${v.count}건` }))
    .sort((a, b) => b.value - a.value)
    .slice(0, 5);

  // Cumulative for area chart
  const cumulativePoints = (() => {
    let acc = 0;
    return last12Months.map((m) => {
      acc += m.paid + m.unpaid;
      return { label: m.shortLabel, value: acc };
    });
  })();

  // Average per active month
  const activeMonths = allMonths.filter((m) => m.count > 0).length || 1;
  const avg = grandTotal / activeMonths;
  const bestMonth = monthsWithData.length > 0
    ? monthsWithData.reduce((a, b) => (a.paid + a.unpaid > b.paid + b.unpaid ? a : b))
    : null;

  return (
    <div className="space-y-5">
      <PageHeader
        title="월 리포트"
        subtitle="월별 정산 현황과 트렌드"
        action={<ReportExportButton items={items} />}
      />

      {/* Top KPI strip */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <Kpi label="총 누적" value={formatKrw(grandTotal)} accent="var(--brand)" />
        <Kpi label="지급 완료" value={formatKrw(totalPaid)} accent="var(--success)" />
        <Kpi label="미지급" value={formatKrw(totalUnpaid)} accent="var(--warning)" />
        <Kpi
          label={`월 평균 (활동 ${activeMonths}개월)`}
          value={formatKrwShort(avg)}
          accent="var(--info)"
        />
      </div>

      {/* Charts row 1: Donut + Area */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <Card padding="lg">
          <h3 className="text-sm font-bold mb-1">지급 상태</h3>
          <p className="text-[11px] mb-5" style={{ color: "var(--text-tertiary)" }}>
            완료 vs 대기 비율
          </p>
          <DonutChart
            slices={[
              { label: "지급 완료", value: totalPaid, color: "var(--success)" },
              { label: "미지급", value: totalUnpaid, color: "var(--warning)" },
            ]}
            centerLabel="실수령 합계"
            centerValue={formatKrwShort(grandTotal)}
          />
        </Card>

        <Card padding="lg">
          <h3 className="text-sm font-bold mb-1">누적 수익 추세</h3>
          <p className="text-[11px] mb-5" style={{ color: "var(--text-tertiary)" }}>
            최근 12개월
          </p>
          <AreaChart points={cumulativePoints} height={180} />
        </Card>
      </div>

      {/* Charts row 2: Monthly bars + Top brands */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        <Card padding="lg">
          <h3 className="text-sm font-bold mb-1">월별 추세</h3>
          <p className="text-[11px] mb-5" style={{ color: "var(--text-tertiary)" }}>
            최근 12개월 (지급 + 미지급)
          </p>
          <MonthlyBars months={last12Months} />
        </Card>

        <Card padding="lg">
          <h3 className="text-sm font-bold mb-1">브랜드 TOP 5</h3>
          <p className="text-[11px] mb-5" style={{ color: "var(--text-tertiary)" }}>
            누적 실수령 기준
          </p>
          {topBrands.length > 0 ? (
            <HorizontalBars rows={topBrands} />
          ) : (
            <p className="text-sm" style={{ color: "var(--text-tertiary)" }}>
              데이터 없음
            </p>
          )}
        </Card>
      </div>

      {/* Best month callout */}
      {bestMonth && (
        <Card padding="lg" className="flex items-center gap-4 overflow-hidden relative">
          <div
            className="w-12 h-12 rounded-2xl flex items-center justify-center text-2xl flex-shrink-0"
            style={{ background: "var(--brand-soft)" }}
          >
            🏆
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-semibold" style={{ color: "var(--text-tertiary)" }}>
              최고 수익 월
            </p>
            <p className="text-lg font-bold mt-0.5">
              {bestMonth.label}
              <span
                className="ml-2 text-sm tabular font-semibold"
                style={{ color: "var(--brand)" }}
              >
                {formatKrw(bestMonth.paid + bestMonth.unpaid)}
              </span>
            </p>
            <p className="text-[11px] mt-0.5" style={{ color: "var(--text-secondary)" }}>
              {bestMonth.count}건 정산
            </p>
          </div>
        </Card>
      )}

      {/* Monthly detail table */}
      <Card padding="lg">
        <h3 className="text-sm font-bold mb-4">월별 상세</h3>
        <div className="space-y-3">
          {monthsWithData.map((m) => {
            const total = m.paid + m.unpaid;
            const paidPct = total === 0 ? 0 : (m.paid / total) * 100;
            return (
              <div key={m.key} className="rounded-xl p-4" style={{ background: "var(--bg)" }}>
                <div className="flex items-center justify-between mb-3">
                  <p className="text-sm font-bold">{m.label}</p>
                  <span className="text-[11px]" style={{ color: "var(--text-secondary)" }}>
                    {m.count}건
                  </span>
                </div>
                <div
                  className="h-2 rounded-full overflow-hidden mb-3"
                  style={{ background: "var(--muted)" }}
                >
                  <div className="h-full flex">
                    <div
                      style={{ width: `${paidPct}%`, background: "var(--success)" }}
                    />
                    <div
                      style={{ width: `${100 - paidPct}%`, background: "var(--warning)" }}
                    />
                  </div>
                </div>
                <div className="grid grid-cols-3 gap-3">
                  <Field label="지급 완료" value={formatKrw(m.paid)} color="var(--success)" />
                  <Field label="미지급" value={formatKrw(m.unpaid)} color="var(--warning)" />
                  <Field label="합계" value={formatKrw(total)} color="var(--text)" />
                </div>
              </div>
            );
          })}
        </div>
      </Card>
    </div>
  );
}

function Kpi({ label, value, accent }: { label: string; value: string; accent: string }) {
  return (
    <Card padding="md">
      <p className="text-[11px] font-semibold" style={{ color: "var(--text-tertiary)" }}>
        {label}
      </p>
      <p className="text-lg font-bold mt-1.5 tabular" style={{ color: accent }}>
        {value}
      </p>
    </Card>
  );
}

function Field({ label, value, color }: { label: string; value: string; color: string }) {
  return (
    <div>
      <p className="text-[11px]" style={{ color: "var(--text-secondary)" }}>
        {label}
      </p>
      <p className="text-sm font-bold tabular" style={{ color }}>
        {value}
      </p>
    </div>
  );
}

function MonthlyBars({ months }: { months: MonthBucket[] }) {
  const max = Math.max(...months.map((m) => m.paid + m.unpaid), 1);
  const currentKey = new Date().toISOString().slice(0, 7);
  return (
    <div className="grid grid-cols-12 gap-1.5" style={{ height: 200 }}>
      {months.map((m) => {
        const total = m.paid + m.unpaid;
        const heightPct = (total / max) * 100;
        const paidPct = total === 0 ? 0 : (m.paid / total) * 100;
        const unpaidPct = 100 - paidPct;
        const isCurrent = m.key === currentKey;
        return (
          <div key={m.key} className="flex flex-col items-center h-full group">
            <div
              className="h-4 text-[9px] font-bold tabular opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap"
              style={{ color: "var(--text)" }}
            >
              {total > 0 ? formatKrwShort(total) : ""}
            </div>
            <div className="flex-1 w-full flex flex-col justify-end">
              {total === 0 ? (
                <div
                  className="w-full rounded-sm"
                  style={{
                    height: 4,
                    background: "var(--muted)",
                    border: "1px dashed var(--border)",
                  }}
                />
              ) : (
                <div
                  className="w-full rounded-md overflow-hidden flex flex-col-reverse"
                  style={{
                    height: `${Math.max(heightPct, 6)}%`,
                    border: isCurrent ? "1.5px solid var(--brand)" : "1px solid var(--border)",
                  }}
                  title={`${m.label}\n지급 ${formatKrw(m.paid)}\n미지급 ${formatKrw(m.unpaid)}`}
                >
                  {m.paid > 0 && (
                    <div style={{ height: `${paidPct}%`, background: "var(--success)" }} />
                  )}
                  {m.unpaid > 0 && (
                    <div style={{ height: `${unpaidPct}%`, background: "var(--warning)" }} />
                  )}
                </div>
              )}
            </div>
            <div
              className="mt-1.5 text-[9px] text-center font-bold"
              style={{ color: isCurrent ? "var(--brand)" : "var(--text-tertiary)" }}
            >
              {m.shortLabel}
            </div>
          </div>
        );
      })}
    </div>
  );
}
