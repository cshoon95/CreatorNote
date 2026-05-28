import Link from "next/link";
import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SponsorshipBadge, ReelsBadge } from "@/components/ui/status-badge";
import { Card } from "@/components/ui/card";
import { Avatar } from "@/components/ui/avatar";
import { formatKrw, formatDate, daysRemaining, isExpired } from "@/lib/format";
import { DetailActions } from "./detail-actions";
import { LinkedNotesSection } from "./linked-notes";
import type { Sponsorship, Settlement, ReelsNote } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function SponsorshipDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const wid = ctx!.workspace!.id;

  const [{ data }, { data: settle }, { data: linked }, { data: allReels }] = await Promise.all([
    supabase.from("sponsorships").select("*").eq("workspace_id", wid).eq("id", id).maybeSingle(),
    supabase.from("settlements").select("*").eq("sponsorship_id", id).maybeSingle(),
    supabase
      .from("reels_notes")
      .select("*")
      .eq("workspace_id", wid)
      .eq("sponsorship_id", id)
      .order("updated_at", { ascending: false }),
    supabase
      .from("reels_notes")
      .select("id, title, status, sponsorship_id, plain_content")
      .eq("workspace_id", wid),
  ]);

  if (!data) notFound();
  const s = data as Sponsorship;
  const settlement = (settle as Settlement | null) ?? null;
  const linkedNotes = (linked ?? []) as ReelsNote[];
  const allReelsList = (allReels ?? []) as ReelsNote[];

  const d = daysRemaining(s.end_date);
  const expired = isExpired(s.end_date);

  return (
    <div>
      <Link href="/sponsorships" className="text-sm inline-flex items-center gap-1" style={{ color: "var(--text-secondary)" }}>
        ← 협찬 목록
      </Link>

      <Card padding="lg" className="mt-4 fadein">
        <div className="flex items-start gap-4">
          <Avatar name={s.brand_name} size={56} />
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <h1 className="text-xl font-bold truncate">{s.brand_name}</h1>
              <SponsorshipBadge status={s.status} />
            </div>
            {s.product_name && (
              <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
                {s.product_name}
              </p>
            )}
          </div>
        </div>

        <div
          className="rounded-2xl p-5 mt-6 relative overflow-hidden"
          style={{ background: "var(--brand-soft)" }}
        >
          <p className="text-xs font-semibold" style={{ color: "var(--text-secondary)" }}>
            계약 금액
          </p>
          <p
            className="text-3xl font-bold mt-1 tabular"
            style={{ color: "var(--brand)" }}
          >
            {formatKrw(s.amount)}
          </p>
        </div>

        <div
          className="grid grid-cols-2 gap-5 mt-6 pt-6 border-t"
          style={{ borderColor: "var(--border)" }}
        >
          <Field label="시작일" value={formatDate(s.start_date)} />
          <Field label="마감일" value={formatDate(s.end_date)} />
          <Field
            label="남은 일수"
            value={!s.end_date ? "—" : expired ? "마감됨" : d === 0 ? "오늘 마감" : `${d}일`}
            highlight={!expired && d <= 3}
          />
          <Field label="상태" value={<SponsorshipBadge status={s.status} />} />
        </div>

        {s.details && (
          <div className="mt-6 pt-6 border-t" style={{ borderColor: "var(--border)" }}>
            <p className="text-xs font-semibold mb-2" style={{ color: "var(--text-secondary)" }}>
              상세 내용
            </p>
            <p className="text-sm whitespace-pre-wrap leading-relaxed">{s.details}</p>
          </div>
        )}
      </Card>

      {settlement && (
        <Link href={`/settlements/${settlement.id}`}>
          <Card hover padding="md" className="mt-4 flex items-center gap-3">
            <div
              className="w-11 h-11 rounded-2xl flex items-center justify-center text-lg"
              style={{ background: "var(--success-soft)" }}
            >
              💰
            </div>
            <div className="flex-1">
              <p className="text-sm font-bold">연결된 정산</p>
              <p className="text-xs" style={{ color: "var(--text-secondary)" }}>
                {settlement.is_paid ? "지급 완료" : "지급 대기"} · 실수령{" "}
                {formatKrw(settlement.amount - settlement.fee - settlement.tax)}
              </p>
            </div>
            <span style={{ color: "var(--text-tertiary)" }}>›</span>
          </Card>
        </Link>
      )}

      <LinkedNotesSection
        sponsorshipId={s.id}
        linkedNotes={linkedNotes}
        unassignedNotes={allReelsList.filter((n) => !n.sponsorship_id || n.sponsorship_id === s.id)}
      />

      <DetailActions id={s.id} brandName={s.brand_name} />
    </div>
  );
}

function Field({
  label,
  value,
  highlight,
}: {
  label: string;
  value: React.ReactNode;
  highlight?: boolean;
}) {
  return (
    <div>
      <p className="text-[11px] font-semibold mb-1" style={{ color: "var(--text-secondary)" }}>
        {label}
      </p>
      <div
        className="text-sm font-bold tabular"
        style={{ color: highlight ? "var(--warning)" : "var(--text)" }}
      >
        {value}
      </div>
    </div>
  );
}

// Suppress unused — exported but only for type
void ReelsBadge;
