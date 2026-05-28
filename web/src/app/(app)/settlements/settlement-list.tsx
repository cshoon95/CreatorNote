"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { toast } from "@/components/toast";
import { formatKrw, formatDate } from "@/lib/format";
import type { Settlement } from "@/lib/types";

type Filter = "all" | "paid" | "unpaid";

export function SettlementList({
  initialItems,
  totalCount,
  pageSize = 100,
}: {
  initialItems: Settlement[];
  totalCount?: number;
  pageSize?: number;
}) {
  const router = useRouter();
  const [items, setItems] = useState(initialItems);
  const [filter, setFilter] = useState<Filter>("all");
  const [query, setQuery] = useState("");
  const [loadingMore, setLoadingMore] = useState(false);
  const total = totalCount ?? initialItems.length;
  const hasMore = items.length < total;

  const loadMore = async () => {
    if (loadingMore || !hasMore) return;
    setLoadingMore(true);
    const supabase = createClient();
    const { data } = await supabase
      .from("settlements")
      .select("*")
      .eq("workspace_id", initialItems[0]?.workspace_id ?? "")
      .order("created_at", { ascending: false })
      .range(items.length, items.length + pageSize - 1);
    if (data) setItems((cur) => [...cur, ...(data as Settlement[])]);
    setLoadingMore(false);
  };

  const visible = useMemo(() => {
    let list = items;
    if (filter === "paid") list = list.filter((s) => s.is_paid);
    if (filter === "unpaid") list = list.filter((s) => !s.is_paid);
    if (query.trim()) {
      const q = query.toLowerCase();
      list = list.filter((s) => s.brand_name.toLowerCase().includes(q));
    }
    return list;
  }, [items, filter, query]);

  const togglePaid = async (s: Settlement) => {
    const next = !s.is_paid;
    setItems((cur) => cur.map((x) => (x.id === s.id ? { ...x, is_paid: next } : x)));
    const supabase = createClient();
    const { error } = await supabase.from("settlements").update({ is_paid: next }).eq("id", s.id).eq("workspace_id", s.workspace_id);
    if (error) {
      toast("변경 실패", "danger");
      setItems((cur) => cur.map((x) => (x.id === s.id ? { ...x, is_paid: !next } : x)));
    } else {
      toast(next ? "✅ 지급 완료로 변경" : "미지급으로 변경", "info");
      router.refresh();
    }
  };

  const remove = async (s: Settlement) => {
    if (!confirm(`${s.brand_name} 정산을 삭제할까요?`)) return;
    const backup = items;
    setItems((cur) => cur.filter((x) => x.id !== s.id));
    const supabase = createClient();
    const { error } = await supabase.from("settlements").delete().eq("id", s.id).eq("workspace_id", s.workspace_id);
    if (error) {
      toast("삭제 실패", "danger");
      setItems(backup);
    } else {
      toast("삭제되었어요", "success");
      router.refresh();
    }
  };

  return (
    <div>
      <input
        className="input mb-3"
        placeholder="브랜드 이름으로 검색"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />
      <div className="flex gap-1.5 mb-4">
        {(
          [
            { v: "all", l: "전체" },
            { v: "unpaid", l: "⏰ 미지급" },
            { v: "paid", l: "✅ 지급 완료" },
          ] as { v: Filter; l: string }[]
        ).map((c) => (
          <button
            key={c.v}
            onClick={() => setFilter(c.v)}
            className={`chip whitespace-nowrap ${filter === c.v ? "chip-active" : ""}`}
          >
            {c.l}
          </button>
        ))}
      </div>

      {visible.length === 0 ? (
        <p className="text-center py-12 text-sm" style={{ color: "var(--text-secondary)" }}>
          조건에 맞는 정산이 없어요
        </p>
      ) : (
        <ul className="grid grid-cols-1 lg:grid-cols-2 gap-2">
          {visible.map((s) => {
            const net = s.amount - s.fee - s.tax;
            return (
              <li key={s.id}>
                <Card hover padding="md" className="flex items-center gap-3 group">
                  <button
                    onClick={() => togglePaid(s)}
                    className="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 transition-all"
                    style={{
                      background: s.is_paid ? "var(--success)" : "transparent",
                      border: s.is_paid ? "none" : "2px solid var(--border-strong)",
                      color: "white",
                    }}
                    aria-label={s.is_paid ? "지급 완료" : "미지급"}
                  >
                    {s.is_paid && "✓"}
                  </button>
                  <Link href={`/settlements/${s.id}`} className="flex-1 min-w-0 -my-1 py-1">
                    <p className="text-sm font-bold truncate">{s.brand_name}</p>
                    <p className="text-xs" style={{ color: "var(--text-secondary)" }}>
                      {formatDate(s.settlement_date)} · 실수령{" "}
                      <span className="font-semibold tabular">{formatKrw(net)}</span>
                    </p>
                  </Link>
                  <div className="text-right">
                    <p
                      className="text-sm font-bold tabular"
                      style={{ color: s.is_paid ? "var(--success)" : "var(--warning)" }}
                    >
                      {formatKrw(s.amount)}
                    </p>
                    {!s.is_paid && (
                      <Badge tone="warning" className="mt-0.5">
                        대기
                      </Badge>
                    )}
                  </div>
                  <button
                    onClick={() => remove(s)}
                    className="opacity-0 group-hover:opacity-100 lg:opacity-100 transition-opacity flex-shrink-0 w-7 h-7 flex items-center justify-center rounded-full hover:bg-[var(--danger-soft)]"
                    aria-label="삭제"
                    style={{ color: "var(--text-tertiary)" }}
                  >
                    ✕
                  </button>
                </Card>
              </li>
            );
          })}
        </ul>
      )}

      {hasMore && (
        <div className="mt-5 text-center">
          <button
            onClick={loadMore}
            disabled={loadingMore}
            className="btn btn-secondary"
          >
            {loadingMore
              ? "불러오는 중..."
              : `더 보기 (${total - items.length}건 남음)`}
          </button>
        </div>
      )}
    </div>
  );
}
