"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useWorkspace } from "@/components/workspace-context";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";
import { toIsoDate, formatKrw } from "@/lib/format";
import type { Settlement, Sponsorship } from "@/lib/types";

interface SettlementFormProps {
  initial?: Settlement;
  sponsorshipOptions: Pick<Sponsorship, "id" | "brand_name" | "amount">[];
}

export function SettlementForm({ initial, sponsorshipOptions }: SettlementFormProps) {
  const router = useRouter();
  const ws = useWorkspace();
  const isEdit = !!initial;

  const [sponsorshipId, setSponsorshipId] = useState(initial?.sponsorship_id ?? "");
  const [brandName, setBrandName] = useState(initial?.brand_name ?? "");
  const [amount, setAmount] = useState(initial?.amount ? String(initial.amount) : "");
  const [fee, setFee] = useState(initial?.fee ? String(initial.fee) : "0");
  // 3.3% withholding auto-mode: on by default if existing tax matches 3.3% of amount
  const [auto33, setAuto33] = useState<boolean>(() => {
    if (!initial) return false;
    const expected = Math.round((initial.amount ?? 0) * 0.033);
    return Math.abs((initial.tax ?? 0) - expected) <= 1 && (initial.amount ?? 0) > 0;
  });
  const [tax, setTax] = useState(initial?.tax ? String(initial.tax) : "0");
  const [settlementDate, setSettlementDate] = useState(
    initial?.settlement_date ? toIsoDate(initial.settlement_date) : toIsoDate(new Date()),
  );
  const [isPaid, setIsPaid] = useState(initial?.is_paid ?? false);
  const [memo, setMemo] = useState(initial?.memo ?? "");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const auto33Tax = Math.round((Number(amount) || 0) * 0.033);
  const effectiveTax = auto33 ? auto33Tax : Number(tax) || 0;
  const net = (Number(amount) || 0) - (Number(fee) || 0) - effectiveTax;

  const onSelectSponsorship = (id: string) => {
    setSponsorshipId(id);
    const found = sponsorshipOptions.find((s) => s.id === id);
    if (found) {
      setBrandName(found.brand_name);
      if (!amount) setAmount(String(found.amount));
    }
  };

  const save = async () => {
    if (!brandName.trim()) {
      setError("브랜드 이름은 필수입니다");
      return;
    }
    setLoading(true);
    setError(null);
    const payload = {
      brand_name: brandName.trim(),
      amount: Number(amount) || 0,
      fee: Number(fee) || 0,
      tax: effectiveTax,
      settlement_date: settlementDate ? new Date(settlementDate).toISOString() : null,
      is_paid: isPaid,
      memo: memo.trim() || null,
      sponsorship_id: sponsorshipId || null,
    };
    const supabase = createClient();
    if (isEdit) {
      const { error: err } = await supabase
        .from("settlements")
        .update(payload)
        .eq("id", initial!.id);
      if (err) {
        setError(err.message);
        setLoading(false);
        return;
      }
      toast("수정되었어요", "success");
      router.push(`/settlements/${initial!.id}`);
      router.refresh();
    } else {
      const { data, error: err } = await supabase
        .from("settlements")
        .insert({ ...payload, workspace_id: ws.workspaceId, created_by: ws.userId })
        .select()
        .single();
      if (err || !data) {
        setError(err?.message ?? "추가 실패");
        setLoading(false);
        return;
      }
      toast("✨ 정산이 등록되었어요", "success");
      router.push(`/settlements/${data.id}`);
      router.refresh();
    }
  };

  return (
    <Card padding="lg" className="space-y-4">
      {sponsorshipOptions.length > 0 && (
        <div>
          <label className="label">연결된 협찬 (선택)</label>
          <select
            className="input"
            value={sponsorshipId}
            onChange={(e) => onSelectSponsorship(e.target.value)}
          >
            <option value="">없음</option>
            {sponsorshipOptions.map((s) => (
              <option key={s.id} value={s.id}>
                {s.brand_name} · {formatKrw(s.amount)}
              </option>
            ))}
          </select>
        </div>
      )}
      <div>
        <label className="label">브랜드 이름 *</label>
        <input
          className="input"
          value={brandName}
          onChange={(e) => setBrandName(e.target.value)}
        />
      </div>
      <div className="grid grid-cols-3 gap-2">
        <div>
          <label className="label">금액</label>
          <input
            className="input tabular"
            inputMode="numeric"
            value={amount}
            onChange={(e) => setAmount(e.target.value.replace(/[^0-9]/g, ""))}
          />
        </div>
        <div>
          <label className="label">수수료</label>
          <input
            className="input tabular"
            inputMode="numeric"
            value={fee}
            onChange={(e) => setFee(e.target.value.replace(/[^0-9]/g, ""))}
          />
        </div>
        <div>
          <label className="label">세금</label>
          <input
            className="input tabular"
            inputMode="numeric"
            value={auto33 ? String(auto33Tax) : tax}
            onChange={(e) => setTax(e.target.value.replace(/[^0-9]/g, ""))}
            disabled={auto33}
          />
        </div>
      </div>

      <button
        type="button"
        onClick={() => setAuto33((v) => !v)}
        className="w-full flex items-center justify-between gap-3 rounded-xl p-3 transition-all"
        style={{
          background: auto33 ? "var(--brand-soft)" : "var(--muted)",
          border: `1px solid ${auto33 ? "color-mix(in srgb, var(--brand) 22%, transparent)" : "var(--border)"}`,
        }}
      >
        <div className="flex items-center gap-2.5">
          <span className="text-base">🧾</span>
          <div className="text-left">
            <p
              className="text-sm font-bold"
              style={{ color: auto33 ? "var(--brand)" : "var(--text)" }}
            >
              원천징수 3.3% 자동 계산
            </p>
            <p className="text-[11px]" style={{ color: "var(--text-secondary)" }}>
              {auto33
                ? `세금 ${formatKrw(auto33Tax)} 자동 적용 중`
                : "프리랜서 표준 원천징수율"}
            </p>
          </div>
        </div>
        <span
          className="relative inline-flex items-center w-10 h-6 rounded-full transition-colors"
          style={{ background: auto33 ? "var(--brand)" : "var(--border-strong)" }}
        >
          <span
            className="absolute top-0.5 w-5 h-5 rounded-full bg-white transition-transform"
            style={{ left: 2, transform: auto33 ? "translateX(16px)" : "translateX(0)" }}
          />
        </span>
      </button>
      <div
        className="rounded-2xl p-4 flex items-center justify-between"
        style={{ background: "var(--gradient-brand-soft)" }}
      >
        <span className="text-sm font-semibold" style={{ color: "var(--text-secondary)" }}>
          실수령액
        </span>
        <span className="text-lg font-bold tabular text-gradient">{formatKrw(net)}</span>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="label">정산일</label>
          <input
            type="date"
            className="input"
            value={settlementDate}
            onChange={(e) => setSettlementDate(e.target.value)}
          />
        </div>
        <div>
          <label className="label">지급 상태</label>
          <button
            type="button"
            onClick={() => setIsPaid((v) => !v)}
            className="input flex items-center justify-between"
          >
            <span>{isPaid ? "✅ 지급 완료" : "⏰ 미지급"}</span>
            <span style={{ color: "var(--text-tertiary)" }}>↻</span>
          </button>
        </div>
      </div>
      <div>
        <label className="label">메모</label>
        <textarea
          className="input min-h-[80px] resize-y"
          value={memo}
          onChange={(e) => setMemo(e.target.value)}
          placeholder="원천징수 영수증 받음, 다음달 25일 입금 예정..."
        />
      </div>
      {error && (
        <p className="text-xs" style={{ color: "var(--danger)" }}>
          {error}
        </p>
      )}
      <div className="flex gap-2 pt-2">
        <Button variant="secondary" onClick={() => router.back()} fullWidth>
          취소
        </Button>
        <Button variant="primary" onClick={save} loading={loading} fullWidth>
          {isEdit ? "수정 저장" : "등록"}
        </Button>
      </div>
    </Card>
  );
}
