import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { formatKrw, daysRemaining, isExpired } from "@/lib/format";
import { ReelsBadge } from "@/components/ui/status-badge";
import { EmptyState } from "@/components/ui/empty-state";
import { Card } from "@/components/ui/card";
import { MonthChart, type MonthDatum } from "@/components/ui/month-chart";
import { DashboardClient } from "./dashboard-client";
import type { Sponsorship, Settlement, ReelsNote, GeneralNote } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const ctx = await getAuthContext();
  const wid = ctx!.workspace!.id;
  const supabase = await createClient();

  const [{ data: sp }, { data: st }, { data: rn }, { data: gn }] = await Promise.all([
    supabase.from("sponsorships").select("*").eq("workspace_id", wid).order("end_date"),
    supabase
      .from("settlements")
      .select("*")
      .eq("workspace_id", wid)
      .order("created_at", { ascending: false }),
    supabase
      .from("reels_notes")
      .select("*")
      .eq("workspace_id", wid)
      .order("updated_at", { ascending: false }),
    supabase
      .from("general_notes")
      .select("*")
      .eq("workspace_id", wid)
      .order("updated_at", { ascending: false }),
  ]);

  const sponsorships = (sp ?? []) as Sponsorship[];
  const settlements = (st ?? []) as Settlement[];
  const reelsNotes = (rn ?? []) as ReelsNote[];
  const generalNotes = (gn ?? []) as GeneralNote[];

  const active = sponsorships.filter((s) => !isExpired(s.end_date));
  const expiringSoon = sponsorships.filter((s) => {
    const d = daysRemaining(s.end_date);
    return d >= 0 && d <= 3 && !isExpired(s.end_date);
  });
  const pending = sponsorships.filter((s) => s.status === "pendingSettlement");
  const pendingAmount = pending.reduce((a, s) => a + (s.amount ?? 0), 0);
  const totalEarnings = settlements
    .filter((s) => s.is_paid)
    .reduce((a, s) => a + ((s.amount ?? 0) - (s.fee ?? 0) - (s.tax ?? 0)), 0);
  const unpaidNet = settlements
    .filter((s) => !s.is_paid)
    .reduce((a, s) => a + ((s.amount ?? 0) - (s.fee ?? 0) - (s.tax ?? 0)), 0);

  const todayDate = new Date();
  todayDate.setHours(0, 0, 0, 0);
  const todayDeadlines = sponsorships.filter((s) => {
    if (!s.end_date) return false;
    const d = new Date(s.end_date);
    d.setHours(0, 0, 0, 0);
    return d.getTime() === todayDate.getTime();
  });
  const draftNotes = reelsNotes.filter((n) => n.status === "drafting").slice(0, 2);
  const nickname = ctx!.profile?.display_name ?? "";

  // 6 month revenue chart
  const months: MonthDatum[] = [];
  const now = new Date();
  for (let i = 5; i >= 0; i--) {
    const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    months.push({
      key,
      label: `${d.getFullYear()}년 ${d.getMonth() + 1}월`,
      paid: 0,
      unpaid: 0,
    });
  }
  for (const s of settlements) {
    const d = s.settlement_date ? new Date(s.settlement_date) : new Date(s.created_at);
    const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    const month = months.find((m) => m.key === key);
    if (!month) continue;
    const net = s.amount - s.fee - s.tax;
    if (s.is_paid) month.paid += net;
    else month.unpaid += net;
  }

  if (sponsorships.length === 0 && reelsNotes.length === 0 && generalNotes.length === 0) {
    return (
      <div className="space-y-6">
        <Greeting nickname={nickname} />
        <EmptyState
          emoji="✨"
          title="새로운 시작이에요"
          description="첫 협찬을 등록하거나 릴스 노트를 작성해 보세요"
          action={{ label: "협찬 추가하기", href: "/sponsorships/new" }}
        />
      </div>
    );
  }

  return (
    <div className="space-y-5">
      <Greeting nickname={nickname} />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <BigStatCard
          href="/sponsorships"
          icon="🤝"
          iconTint="var(--info-tint)"
          title="이번 달 협찬"
          mainLabel="진행 중"
          mainValue={`${active.length}건`}
          mainAccent="var(--info)"
          breakdown={[
            {
              label: "정산 대기",
              value: `${pending.length}건`,
              dotColor: "var(--warning)",
              soft: "var(--warning-soft)",
            },
            {
              label: "마감 임박",
              value: `${expiringSoon.length}건`,
              dotColor: "var(--danger)",
              soft: "var(--danger-soft)",
            },
          ]}
          footerLeft={{ label: "전체 협찬", value: `${sponsorships.length}건` }}
          footerRight={{
            label: "예정 정산액",
            value: formatKrw(pendingAmount),
            accent: "var(--warning)",
          }}
        />

        <BigStatCard
          href="/settlements"
          icon="💰"
          iconTint="var(--success-tint)"
          title="정산 현황"
          mainLabel="총 실수령"
          mainValue={formatKrw(totalEarnings)}
          mainAccent="var(--success)"
          breakdown={[
            {
              label: "지급 완료",
              value: `${settlements.filter((s) => s.is_paid).length}건`,
              dotColor: "var(--success)",
              soft: "var(--success-soft)",
            },
            {
              label: "미지급",
              value: `${settlements.filter((s) => !s.is_paid).length}건`,
              dotColor: "var(--warning)",
              soft: "var(--warning-soft)",
            },
          ]}
          footerLeft={{ label: "정산 건수", value: `${settlements.length}건` }}
          footerRight={{
            label: "미지급 실수령",
            value: formatKrw(unpaidNet),
            accent: "var(--warning)",
          }}
        />
      </div>

      {settlements.length > 0 && <MonthChart data={months} />}

      <DashboardClient
        todayDeadlines={todayDeadlines}
        expiringSoon={expiringSoon}
        pending={pending}
        pendingAmount={pendingAmount}
        draftNotes={draftNotes}
      />

      {(reelsNotes.length > 0 || generalNotes.length > 0) && (
        <section>
          <div className="flex items-center justify-between mb-3 px-1">
            <h3 className="text-sm font-bold flex items-center gap-2">
              <span>📝</span>
              최근 노트
            </h3>
            <Link
              href="/notes"
              className="text-xs font-semibold"
              style={{ color: "var(--brand)" }}
            >
              전체 보기 →
            </Link>
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-2">
            {reelsNotes.slice(0, 4).map((n) => (
              <Link key={n.id} href={`/notes/reels/${n.id}`}>
                <Card hover padding="md" className="h-full">
                  <div className="flex items-start gap-3">
                    <div
                      className="w-1 self-stretch rounded-full flex-shrink-0"
                      style={{ background: "var(--brand)" }}
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-bold truncate">
                          {n.title || "제목 없음"}
                        </p>
                        <ReelsBadge status={n.status} />
                      </div>
                      <p
                        className="text-xs truncate"
                        style={{ color: "var(--text-secondary)" }}
                      >
                        {n.plain_content || "내용 없음"}
                      </p>
                    </div>
                  </div>
                </Card>
              </Link>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}

function Greeting({ nickname }: { nickname: string }) {
  const dateString = new Date().toLocaleDateString("ko-KR", {
    year: "numeric",
    month: "long",
    day: "numeric",
    weekday: "short",
  });
  return (
    <div className="flex items-end justify-between gap-3">
      <div>
        <h1 className="text-2xl lg:text-3xl font-bold tracking-tight">
          안녕하세요,{" "}
          <span style={{ color: "var(--brand)" }}>{nickname || "크리에이터"}님</span>
        </h1>
        <p className="text-sm mt-1.5" style={{ color: "var(--text-secondary)" }}>
          오늘도 멋진 콘텐츠 만들어요
        </p>
      </div>
      <span
        className="hidden sm:inline-block text-xs font-medium px-3 py-1.5 rounded-lg"
        style={{
          background: "var(--surface)",
          color: "var(--text-secondary)",
          border: "1px solid var(--border)",
        }}
      >
        {dateString}
      </span>
    </div>
  );
}

interface BigStatCardProps {
  href: string;
  icon: string;
  iconTint: string;
  title: string;
  mainLabel: string;
  mainValue: string;
  mainAccent: string;
  breakdown: { label: string; value: string; dotColor: string; soft: string }[];
  footerLeft: { label: string; value: string };
  footerRight: { label: string; value: string; accent: string };
}

function BigStatCard({
  href,
  icon,
  iconTint,
  title,
  mainLabel,
  mainValue,
  mainAccent,
  breakdown,
  footerLeft,
  footerRight,
}: BigStatCardProps) {
  return (
    <Link href={href}>
      <Card hover padding="lg" className="h-full">
        <div className="flex items-center justify-between mb-5">
          <div className="flex items-center gap-2.5">
            <div
              className="w-9 h-9 rounded-xl flex items-center justify-center text-base"
              style={{ background: iconTint }}
            >
              {icon}
            </div>
            <p className="text-sm font-bold">{title}</p>
          </div>
          <span style={{ color: "var(--text-tertiary)" }}>›</span>
        </div>

        <div className="flex items-baseline justify-between mb-4">
          <p className="text-xs font-medium" style={{ color: "var(--text-secondary)" }}>
            {mainLabel}
          </p>
          <p className="text-2xl font-bold tabular" style={{ color: mainAccent }}>
            {mainValue}
          </p>
        </div>

        <div className="grid grid-cols-2 gap-2 mb-4">
          {breakdown.map((b) => (
            <div
              key={b.label}
              className="rounded-xl p-3"
              style={{ background: b.soft }}
            >
              <div className="flex items-center gap-1.5 mb-1">
                <span
                  className="w-1.5 h-1.5 rounded-full"
                  style={{ background: b.dotColor }}
                />
                <p
                  className="text-[11px] font-semibold"
                  style={{ color: "var(--text-secondary)" }}
                >
                  {b.label}
                </p>
              </div>
              <p className="text-base font-bold tabular">{b.value}</p>
            </div>
          ))}
        </div>

        <div
          className="flex items-center justify-between pt-3 border-t"
          style={{ borderColor: "var(--border)" }}
        >
          <div>
            <p className="text-[11px]" style={{ color: "var(--text-tertiary)" }}>
              {footerLeft.label}
            </p>
            <p className="text-sm font-semibold tabular">{footerLeft.value}</p>
          </div>
          <div className="text-right">
            <p className="text-[11px]" style={{ color: "var(--text-tertiary)" }}>
              {footerRight.label}
            </p>
            <p
              className="text-sm font-bold tabular"
              style={{ color: footerRight.accent }}
            >
              {footerRight.value}
            </p>
          </div>
        </div>
      </Card>
    </Link>
  );
}
