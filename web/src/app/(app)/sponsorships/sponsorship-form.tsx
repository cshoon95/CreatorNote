"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useWorkspace } from "@/components/workspace-context";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";
import { toIsoDate } from "@/lib/format";
import {
  ACTIVE_SPONSORSHIP_STATUSES,
  SPONSORSHIP_STATUS_LABEL,
  type Sponsorship,
  type SponsorshipStatus,
} from "@/lib/types";

interface SponsorshipFormProps {
  initial?: Sponsorship;
  brandSuggestions?: string[];
}

export function SponsorshipForm({ initial, brandSuggestions = [] }: SponsorshipFormProps) {
  const router = useRouter();
  const ws = useWorkspace();
  const isEdit = !!initial;

  const today = new Date();
  const monthLater = new Date(today.getTime() + 30 * 86_400_000);

  const [brandName, setBrandName] = useState(initial?.brand_name ?? "");
  const [productName, setProductName] = useState(initial?.product_name ?? "");
  const [details, setDetails] = useState(initial?.details ?? "");
  const [amount, setAmount] = useState<string>(initial?.amount ? String(initial.amount) : "");
  const [startDate, setStartDate] = useState(
    initial?.start_date ? toIsoDate(initial.start_date) : toIsoDate(today),
  );
  const [endDate, setEndDate] = useState(
    initial?.end_date ? toIsoDate(initial.end_date) : toIsoDate(monthLater),
  );
  const [status, setStatus] = useState<SponsorshipStatus>(initial?.status ?? "preSubmit");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const save = async () => {
    if (!brandName.trim()) {
      setError("브랜드 이름은 필수입니다");
      return;
    }
    setLoading(true);
    setError(null);
    const supabase = createClient();
    const payload = {
      brand_name: brandName.trim(),
      product_name: productName.trim() || null,
      details: details.trim() || null,
      amount: Number(amount) || 0,
      start_date: new Date(startDate).toISOString(),
      end_date: new Date(endDate).toISOString(),
      status,
    };
    if (isEdit) {
      const wasPending = initial!.status === "pendingSettlement";
      const becomesCompleted = status === "completed";
      const { error: err } = await supabase
        .from("sponsorships")
        .update(payload)
        .eq("id", initial!.id);
      if (err) {
        setError(err.message);
        setLoading(false);
        return;
      }
      if (wasPending && becomesCompleted) {
        await supabase.from("settlements").insert({
          workspace_id: ws.workspaceId,
          created_by: ws.userId,
          sponsorship_id: initial!.id,
          brand_name: payload.brand_name,
          amount: payload.amount,
          fee: 0,
          tax: 0,
          settlement_date: new Date().toISOString(),
          is_paid: false,
          memo: "협찬 완료 자동 생성",
        });
      }
      toast("수정되었어요", "success");
      router.push(`/sponsorships/${initial!.id}`);
      router.refresh();
    } else {
      const { data, error: err } = await supabase
        .from("sponsorships")
        .insert({
          ...payload,
          workspace_id: ws.workspaceId,
          created_by: ws.userId,
          is_pinned: false,
        })
        .select()
        .single();
      if (err || !data) {
        setError(err?.message ?? "추가 실패");
        setLoading(false);
        return;
      }
      toast("✨ 협찬이 등록되었어요", "success");
      router.push(`/sponsorships/${data.id}`);
      router.refresh();
    }
  };

  return (
    <Card padding="lg" className="space-y-4">
      <div>
        <label className="label">브랜드 이름 *</label>
        <input
          className="input"
          value={brandName}
          onChange={(e) => setBrandName(e.target.value)}
          placeholder="예: 한화생명"
          autoFocus
          list="brand-suggestions"
        />
        <datalist id="brand-suggestions">
          {brandSuggestions.map((b) => (
            <option key={b} value={b} />
          ))}
        </datalist>
        {brandSuggestions.length > 0 && (
          <p className="text-[11px] mt-1.5" style={{ color: "var(--text-tertiary)" }}>
            💡 최근 거래 브랜드를 입력란에서 자동완성으로 선택할 수 있어요
          </p>
        )}
      </div>
      <div>
        <label className="label">제품 / 캠페인</label>
        <input
          className="input"
          value={productName}
          onChange={(e) => setProductName(e.target.value)}
          placeholder="예: 신상품 런칭 릴스"
        />
      </div>
      <div>
        <label className="label">상세 내용</label>
        <textarea
          className="input min-h-[100px] resize-y"
          value={details}
          onChange={(e) => setDetails(e.target.value)}
          placeholder="가이드라인, 해시태그, 마감 조건..."
        />
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="label">시작일</label>
          <input
            type="date"
            className="input"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
          />
        </div>
        <div>
          <label className="label">마감일</label>
          <input
            type="date"
            className="input"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
          />
        </div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="label">금액 (원)</label>
          <input
            className="input tabular"
            inputMode="numeric"
            value={amount}
            onChange={(e) => setAmount(e.target.value.replace(/[^0-9]/g, ""))}
            placeholder="0"
          />
        </div>
        <div>
          <label className="label">상태</label>
          <select
            className="input"
            value={status}
            onChange={(e) => setStatus(e.target.value as SponsorshipStatus)}
          >
            {ACTIVE_SPONSORSHIP_STATUSES.map((s) => (
              <option key={s} value={s}>
                {SPONSORSHIP_STATUS_LABEL[s]}
              </option>
            ))}
          </select>
        </div>
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
