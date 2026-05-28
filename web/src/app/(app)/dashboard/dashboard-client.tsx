"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Card } from "@/components/ui/card";
import { Modal } from "@/components/ui/modal";
import { Button } from "@/components/ui/button";
import { ReelsBadge, SponsorshipBadge } from "@/components/ui/status-badge";
import { useWorkspace } from "@/components/workspace-context";
import { toast } from "@/components/toast";
import { formatKrw, daysRemaining, formatDate } from "@/lib/format";
import {
  ACTIVE_SPONSORSHIP_STATUSES,
  SPONSORSHIP_STATUS_LABEL,
  type Sponsorship,
  type SponsorshipStatus,
  type ReelsNote,
} from "@/lib/types";

interface DashboardClientProps {
  todayDeadlines: Sponsorship[];
  expiringSoon: Sponsorship[];
  pending: Sponsorship[];
  pendingAmount: number;
  draftNotes: ReelsNote[];
}

type QuickEditTarget =
  | { kind: "sponsor"; item: Sponsorship }
  | { kind: "note"; item: ReelsNote }
  | null;

export function DashboardClient({
  todayDeadlines,
  expiringSoon,
  pending,
  pendingAmount,
  draftNotes,
}: DashboardClientProps) {
  const [target, setTarget] = useState<QuickEditTarget>(null);

  const hasToday = todayDeadlines.length > 0 || expiringSoon.length > 0 || draftNotes.length > 0;
  const hasPending = pending.length > 0;

  if (!hasToday && !hasPending) return null;

  const todayItems = (
    <div className="space-y-2">
      {todayDeadlines.map((s) => (
        <ActionRow
          key={s.id}
          onClick={() => setTarget({ kind: "sponsor", item: s })}
          emoji="🔥"
          iconBg="var(--danger-tint)"
          title={s.brand_name}
          sub="오늘 마감!"
          right={<Pill tone="danger">D-Day</Pill>}
        />
      ))}
      {expiringSoon
        .filter((s) => !todayDeadlines.some((t) => t.id === s.id))
        .map((s) => (
          <ActionRow
            key={s.id}
            onClick={() => setTarget({ kind: "sponsor", item: s })}
            emoji="⏰"
            iconBg="var(--warning-tint)"
            title={s.brand_name}
            sub={`${daysRemaining(s.end_date)}일 후 마감`}
            right={<Pill tone="warning">D-{daysRemaining(s.end_date)}</Pill>}
          />
        ))}
      {draftNotes.map((n) => (
        <ActionRow
          key={n.id}
          onClick={() => setTarget({ kind: "note", item: n })}
          emoji="✏️"
          iconBg="var(--brand-soft)"
          title={n.title || "제목 없음"}
          sub="작성 중인 노트"
          right={<ReelsBadge status={n.status} />}
        />
      ))}
    </div>
  );

  const pendingItems = (
    <div className="space-y-2">
      {pending.map((s) => (
        <ActionRow
          key={s.id}
          onClick={() => setTarget({ kind: "sponsor", item: s })}
          emoji="⏰"
          iconBg="var(--warning-tint)"
          title={s.brand_name}
          sub={s.product_name ?? formatDate(s.end_date)}
          right={
            <span className="text-sm font-bold tabular" style={{ color: "var(--warning)" }}>
              {formatKrw(s.amount)}
            </span>
          }
        />
      ))}
    </div>
  );

  return (
    <>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {hasToday && (
          <Section title="오늘 할 일" emoji="✅">
            {todayItems}
          </Section>
        )}
        {hasPending && (
          <Section
            title="정산 대기"
            emoji="⏳"
            aside={
              <span className="text-sm font-bold tabular" style={{ color: "var(--warning)" }}>
                {formatKrw(pendingAmount)}
              </span>
            }
          >
            {pendingItems}
          </Section>
        )}
      </div>

      <Modal
        open={target?.kind === "sponsor"}
        onClose={() => setTarget(null)}
        title="협찬 빠른 수정"
      >
        {target?.kind === "sponsor" && (
          <SponsorQuickEdit item={target.item} onClose={() => setTarget(null)} />
        )}
      </Modal>

      <Modal
        open={target?.kind === "note"}
        onClose={() => setTarget(null)}
        title="노트 빠른 수정"
      >
        {target?.kind === "note" && (
          <NoteQuickEdit item={target.item} onClose={() => setTarget(null)} />
        )}
      </Modal>
    </>
  );
}

function Section({
  title,
  emoji,
  aside,
  children,
}: {
  title: string;
  emoji: string;
  aside?: React.ReactNode;
  children: React.ReactNode;
}) {
  return (
    <section>
      <div className="flex items-center justify-between mb-3 px-1">
        <h3 className="text-sm font-bold flex items-center gap-2">
          <span>{emoji}</span>
          {title}
        </h3>
        {aside}
      </div>
      {children}
    </section>
  );
}

function ActionRow({
  onClick,
  emoji,
  iconBg,
  title,
  sub,
  right,
}: {
  onClick: () => void;
  emoji: string;
  iconBg: string;
  title: string;
  sub: string;
  right: React.ReactNode;
}) {
  return (
    <button onClick={onClick} className="w-full text-left">
      <Card hover padding="md" className="flex items-center gap-3">
        <div
          className="w-11 h-11 rounded-2xl flex items-center justify-center text-lg flex-shrink-0"
          style={{ background: iconBg }}
        >
          {emoji}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-bold truncate">{title}</p>
          <p className="text-xs truncate" style={{ color: "var(--text-secondary)" }}>
            {sub}
          </p>
        </div>
        {right}
      </Card>
    </button>
  );
}

function Pill({ tone, children }: { tone: "danger" | "warning"; children: React.ReactNode }) {
  const bg = tone === "danger" ? "var(--danger)" : "var(--warning)";
  return (
    <span
      className="text-xs font-bold px-2.5 py-1 rounded-full text-white"
      style={{ background: bg }}
    >
      {children}
    </span>
  );
}

function SponsorQuickEdit({
  item,
  onClose,
}: {
  item: Sponsorship;
  onClose: () => void;
}) {
  const router = useRouter();
  const ws = useWorkspace();
  const [status, setStatus] = useState<SponsorshipStatus>(item.status);
  const [amount, setAmount] = useState(String(item.amount ?? 0));
  const [busy, setBusy] = useState(false);

  const save = async () => {
    setBusy(true);
    const supabase = createClient();
    const newAmount = Number(amount) || 0;
    const becomesCompleted = item.status === "pendingSettlement" && status === "completed";
    const { error } = await supabase
      .from("sponsorships")
      .update({ status, amount: newAmount })
      .eq("id", item.id);
    if (error) {
      toast("저장 실패: " + error.message, "danger");
      setBusy(false);
      return;
    }
    if (becomesCompleted) {
      await supabase.from("settlements").insert({
        workspace_id: ws.workspaceId,
        created_by: ws.userId,
        sponsorship_id: item.id,
        brand_name: item.brand_name,
        amount: newAmount,
        fee: 0,
        tax: 0,
        settlement_date: new Date().toISOString(),
        is_paid: false,
        memo: "협찬 완료 자동 생성",
      });
      toast("💰 정산이 자동 생성되었어요", "success");
    } else {
      toast("저장되었어요", "success");
    }
    onClose();
    router.refresh();
  };

  return (
    <div className="space-y-4">
      <div
        className="flex items-center justify-between rounded-xl p-3"
        style={{ background: "var(--muted)" }}
      >
        <div>
          <p className="text-sm font-bold">{item.brand_name}</p>
          {item.product_name && (
            <p className="text-xs" style={{ color: "var(--text-secondary)" }}>
              {item.product_name}
            </p>
          )}
        </div>
        <SponsorshipBadge status={item.status} />
      </div>

      <div>
        <label className="label">상태</label>
        <div className="grid grid-cols-2 gap-1.5">
          {ACTIVE_SPONSORSHIP_STATUSES.map((s) => (
            <button
              key={s}
              onClick={() => setStatus(s)}
              className="py-2 rounded-lg text-xs font-semibold transition-colors"
              style={{
                background: status === s ? "var(--brand)" : "var(--surface)",
                color: status === s ? "white" : "var(--text-secondary)",
                border:
                  status === s ? "1px solid var(--brand)" : "1px solid var(--border)",
              }}
            >
              {SPONSORSHIP_STATUS_LABEL[s]}
            </button>
          ))}
        </div>
      </div>

      <div>
        <label className="label">금액 (원)</label>
        <input
          className="input tabular"
          inputMode="numeric"
          value={amount}
          onChange={(e) => setAmount(e.target.value.replace(/[^0-9]/g, ""))}
        />
      </div>

      <div className="flex gap-2 pt-2">
        <Link
          href={`/sponsorships/${item.id}`}
          className="btn btn-ghost text-xs"
          onClick={onClose}
        >
          상세 보기
        </Link>
        <span className="flex-1" />
        <Button variant="secondary" onClick={onClose} size="md">
          취소
        </Button>
        <Button variant="primary" onClick={save} loading={busy} size="md">
          저장
        </Button>
      </div>
    </div>
  );
}

function NoteQuickEdit({ item, onClose }: { item: ReelsNote; onClose: () => void }) {
  const router = useRouter();
  const [status, setStatus] = useState(item.status);
  const [busy, setBusy] = useState(false);

  const save = async () => {
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase.from("reels_notes").update({ status }).eq("id", item.id);
    if (error) {
      toast("저장 실패", "danger");
      setBusy(false);
      return;
    }
    toast("저장되었어요", "success");
    onClose();
    router.refresh();
  };

  return (
    <div className="space-y-4">
      <div
        className="rounded-xl p-3"
        style={{ background: "var(--muted)" }}
      >
        <p className="text-sm font-bold truncate">{item.title || "제목 없음"}</p>
        <p
          className="text-xs truncate mt-0.5"
          style={{ color: "var(--text-secondary)" }}
        >
          {item.plain_content || "내용 없음"}
        </p>
      </div>
      <div>
        <label className="label">상태</label>
        <div className="grid grid-cols-3 gap-1.5">
          {(["drafting", "readyToUpload", "uploaded"] as const).map((s) => {
            const label =
              s === "drafting" ? "작성중" : s === "readyToUpload" ? "업로드 대기" : "업로드 완료";
            return (
              <button
                key={s}
                onClick={() => setStatus(s)}
                className="py-2 rounded-lg text-xs font-semibold transition-colors"
                style={{
                  background: status === s ? "var(--brand)" : "var(--surface)",
                  color: status === s ? "white" : "var(--text-secondary)",
                  border:
                    status === s ? "1px solid var(--brand)" : "1px solid var(--border)",
                }}
              >
                {label}
              </button>
            );
          })}
        </div>
      </div>
      <div className="flex gap-2 pt-2">
        <Link
          href={`/notes/reels/${item.id}`}
          className="btn btn-ghost text-xs"
          onClick={onClose}
        >
          전체 편집
        </Link>
        <span className="flex-1" />
        <Button variant="secondary" onClick={onClose} size="md">
          취소
        </Button>
        <Button variant="primary" onClick={save} loading={busy} size="md">
          저장
        </Button>
      </div>
    </div>
  );
}
