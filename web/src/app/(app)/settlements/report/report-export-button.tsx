"use client";

import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";
import { downloadCsv, toCsv } from "@/lib/csv";
import { formatDate } from "@/lib/format";
import type { Settlement } from "@/lib/types";

export function ReportExportButton({ items }: { items: Settlement[] }) {
  const download = () => {
    if (items.length === 0) {
      toast("내보낼 정산이 없어요", "warning");
      return;
    }
    const rows = items.map((s) => ({
      정산일: formatDate(s.settlement_date ?? s.created_at),
      브랜드: s.brand_name,
      "금액(원)": s.amount,
      "수수료(원)": s.fee,
      "세금(원)": s.tax,
      "실수령(원)": s.amount - s.fee - s.tax,
      지급상태: s.is_paid ? "지급 완료" : "미지급",
      메모: s.memo ?? "",
    }));
    const csv = toCsv(rows);
    const today = new Date().toISOString().slice(0, 10);
    downloadCsv(`influe-settlements-${today}.csv`, csv);
    toast("✅ CSV 다운로드 시작", "success");
  };
  return (
    <Button variant="secondary" onClick={download} iconLeft={<span>📥</span>}>
      엑셀(CSV) 내보내기
    </Button>
  );
}
