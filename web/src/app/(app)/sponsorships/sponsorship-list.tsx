"use client";

import { useMemo, useState, useRef, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar } from "@/components/ui/avatar";
import { formatKrw, formatDate, daysRemaining, isExpired } from "@/lib/format";
import { toast } from "@/components/toast";
import {
  ACTIVE_SPONSORSHIP_STATUSES,
  SPONSORSHIP_STATUS_LABEL,
  type Sponsorship,
  type SponsorshipStatus,
} from "@/lib/types";

type Filter = "all" | SponsorshipStatus | "expiringSoon";

const STATUS_TONE: Record<SponsorshipStatus, "default" | "info" | "warning" | "success"> = {
  preSubmit: "default",
  underReview: "info",
  submitted: "success",
  pendingSettlement: "warning",
  completed: "success",
};

export function SponsorshipList({
  initialItems,
  totalCount,
  pageSize = 100,
}: {
  initialItems: Sponsorship[];
  totalCount?: number;
  pageSize?: number;
}) {
  const router = useRouter();
  const [items, setItems] = useState(initialItems);
  const [filter, setFilter] = useState<Filter>("all");
  const [query, setQuery] = useState("");
  const [statusMenuFor, setStatusMenuFor] = useState<string | null>(null);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [loadingMore, setLoadingMore] = useState(false);
  const [bulkBusy, setBulkBusy] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const total = totalCount ?? initialItems.length;
  const hasMore = items.length < total;

  useEffect(() => {
    if (!statusMenuFor) return;
    const close = (e: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
        setStatusMenuFor(null);
      }
    };
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, [statusMenuFor]);

  const visible = useMemo(() => {
    let list = items;
    if (filter === "expiringSoon") {
      list = list.filter((s) => {
        const d = daysRemaining(s.end_date);
        return d >= 0 && d <= 7 && !isExpired(s.end_date);
      });
    } else if (filter !== "all") {
      list = list.filter((s) => s.status === filter);
    }
    if (query.trim()) {
      const q = query.toLowerCase();
      list = list.filter(
        (s) =>
          s.brand_name.toLowerCase().includes(q) ||
          (s.product_name ?? "").toLowerCase().includes(q),
      );
    }
    return list;
  }, [items, filter, query]);

  const togglePin = async (s: Sponsorship) => {
    const next = !s.is_pinned;
    setItems((cur) =>
      [...cur.map((x) => (x.id === s.id ? { ...x, is_pinned: next } : x))].sort(sortFn),
    );
    const supabase = createClient();
    const { error } = await supabase.from("sponsorships").update({ is_pinned: next }).eq("id", s.id).eq("workspace_id", s.workspace_id);
    if (error) {
      toast("고정 변경에 실패했습니다", "danger");
      setItems((cur) => cur.map((x) => (x.id === s.id ? { ...x, is_pinned: !next } : x)));
    } else {
      toast(next ? "📌 고정되었습니다" : "고정 해제됨", "info");
    }
  };

  const changeStatus = async (s: Sponsorship, next: SponsorshipStatus) => {
    setStatusMenuFor(null);
    if (next === s.status) return;
    const prev = s.status;
    setItems((cur) => cur.map((x) => (x.id === s.id ? { ...x, status: next } : x)));
    const supabase = createClient();
    const becomesCompleted = prev === "pendingSettlement" && next === "completed";
    const { error } = await supabase.from("sponsorships").update({ status: next }).eq("id", s.id).eq("workspace_id", s.workspace_id);
    if (error) {
      toast("상태 변경 실패", "danger");
      setItems((cur) => cur.map((x) => (x.id === s.id ? { ...x, status: prev } : x)));
      return;
    }
    if (becomesCompleted) {
      // Auto-create settlement — but skip if one already exists for this sponsor
      const { data: existing } = await supabase
        .from("settlements")
        .select("id")
        .eq("sponsorship_id", s.id)
        .maybeSingle();
      if (!existing) {
        const { data: ud } = await supabase.auth.getUser();
        await supabase.from("settlements").insert({
          workspace_id: s.workspace_id,
          created_by: ud.user?.id ?? s.created_by,
          sponsorship_id: s.id,
          brand_name: s.brand_name,
          amount: s.amount,
          fee: 0,
          tax: 0,
          settlement_date: new Date().toISOString(),
          is_paid: false,
          memo: "협찬 완료 자동 생성",
        });
        toast("💰 정산이 자동 생성되었어요", "success");
      } else {
        toast(`상태: ${SPONSORSHIP_STATUS_LABEL[next]} (정산은 이미 있어요)`, "info");
      }
    } else {
      toast(`상태: ${SPONSORSHIP_STATUS_LABEL[next]}`, "success");
    }
    router.refresh();
  };

  const remove = async (s: Sponsorship) => {
    const backup = items;
    setItems((cur) => cur.filter((x) => x.id !== s.id));
    const supabase = createClient();
    const { error } = await supabase.from("sponsorships").delete().eq("id", s.id).eq("workspace_id", s.workspace_id);
    if (error) {
      toast("삭제에 실패했습니다", "danger");
      setItems(backup);
      return;
    }
    // Undo: re-insert via direct row (server returns nothing here, so we reinsert
    // the original row data including timestamps).
    toast(`${s.brand_name} 삭제됨`, {
      tone: "success",
      action: {
        label: "되돌리기",
        onClick: async () => {
          const reinsert = {
            id: s.id,
            workspace_id: s.workspace_id,
            created_by: s.created_by,
            brand_name: s.brand_name,
            product_name: s.product_name,
            details: s.details,
            amount: s.amount,
            start_date: s.start_date,
            end_date: s.end_date,
            status: s.status,
            is_pinned: s.is_pinned,
          };
          const { error: e2 } = await supabase.from("sponsorships").insert(reinsert);
          if (e2) {
            toast("되돌리기 실패", "danger");
            return;
          }
          setItems((cur) => [...cur, s].sort(sortFn));
          toast("되돌렸어요", "info");
          router.refresh();
        },
      },
    });
    router.refresh();
  };

  const loadMore = async () => {
    if (loadingMore || !hasMore) return;
    setLoadingMore(true);
    const supabase = createClient();
    const { data } = await supabase
      .from("sponsorships")
      .select("*")
      .eq("workspace_id", initialItems[0]?.workspace_id ?? "")
      .order("is_pinned", { ascending: false })
      .order("end_date")
      .range(items.length, items.length + pageSize - 1);
    if (data) setItems((cur) => [...cur, ...(data as Sponsorship[])]);
    setLoadingMore(false);
  };

  const toggleSelected = (id: string) => {
    setSelected((cur) => {
      const next = new Set(cur);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const clearSelection = () => setSelected(new Set());

  const bulkDelete = async () => {
    if (selected.size === 0) return;
    if (!confirm(`선택한 ${selected.size}건 협찬을 삭제할까요?`)) return;
    setBulkBusy(true);
    const ids = Array.from(selected);
    const backup = items;
    setItems((cur) => cur.filter((x) => !selected.has(x.id)));
    const supabase = createClient();
    const { error } = await supabase.from("sponsorships").delete().in("id", ids);
    setBulkBusy(false);
    if (error) {
      toast("일괄 삭제 실패", "danger");
      setItems(backup);
      return;
    }
    toast(`${ids.length}건 삭제됨`, "success");
    clearSelection();
    router.refresh();
  };

  const bulkChangeStatus = async (next: SponsorshipStatus) => {
    if (selected.size === 0) return;
    setBulkBusy(true);
    const ids = Array.from(selected);
    setItems((cur) => cur.map((x) => (selected.has(x.id) ? { ...x, status: next } : x)));
    const supabase = createClient();
    const { error } = await supabase
      .from("sponsorships")
      .update({ status: next })
      .in("id", ids);
    setBulkBusy(false);
    if (error) {
      toast("일괄 상태 변경 실패", "danger");
      router.refresh();
      return;
    }
    toast(`${ids.length}건 상태: ${SPONSORSHIP_STATUS_LABEL[next]}`, "success");
    clearSelection();
    router.refresh();
  };

  return (
    <div>
      {selected.size > 0 && (
        <div
          className="sticky top-2 z-20 mb-3 rounded-2xl px-4 py-3 flex items-center gap-2 fadein"
          style={{
            background: "var(--brand)",
            color: "white",
            boxShadow: "var(--shadow-lg)",
          }}
        >
          <button
            onClick={clearSelection}
            className="w-7 h-7 rounded-full flex items-center justify-center text-xs hover:bg-white/20"
            aria-label="선택 해제"
          >
            ✕
          </button>
          <span className="text-sm font-bold flex-1">{selected.size}건 선택됨</span>
          <select
            disabled={bulkBusy}
            onChange={(e) => {
              const v = e.target.value as SponsorshipStatus | "";
              if (v) bulkChangeStatus(v);
              e.target.value = "";
            }}
            className="text-xs font-semibold px-2.5 py-1.5 rounded-lg"
            style={{ background: "rgba(255,255,255,0.18)", color: "white", border: "none" }}
          >
            <option value="">상태 변경</option>
            {ACTIVE_SPONSORSHIP_STATUSES.map((s) => (
              <option key={s} value={s} style={{ color: "#000" }}>
                → {SPONSORSHIP_STATUS_LABEL[s]}
              </option>
            ))}
          </select>
          <button
            onClick={bulkDelete}
            disabled={bulkBusy}
            className="text-xs font-bold px-3 py-1.5 rounded-lg"
            style={{ background: "rgba(255,255,255,0.2)" }}
          >
            🗑 삭제
          </button>
        </div>
      )}

      <div className="flex items-center gap-2 mb-4">
        <div className="flex-1 relative">
          <span
            className="absolute left-3.5 top-1/2 -translate-y-1/2"
            style={{ color: "var(--text-tertiary)" }}
            aria-hidden
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <circle cx="11" cy="11" r="7" />
              <path d="m21 21-4.3-4.3" />
            </svg>
          </span>
          <input
            className="input"
            style={{ paddingLeft: "2.5rem" }}
            placeholder="브랜드 또는 제품 검색"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
        </div>
      </div>

      <FilterChips filter={filter} onChange={setFilter} />

      {visible.length === 0 ? (
        <p className="text-center py-12 text-sm" style={{ color: "var(--text-secondary)" }}>
          조건에 맞는 협찬이 없어요
        </p>
      ) : (
        <ul className="grid grid-cols-1 lg:grid-cols-2 gap-2 mt-4">
          {visible.map((s) => (
            <li key={s.id} className="relative">
              <SponsorshipRow
                item={s}
                isSelected={selected.has(s.id)}
                hasAnySelected={selected.size > 0}
                onToggleSelect={() => toggleSelected(s.id)}
                onTogglePin={() => togglePin(s)}
                onDelete={() => remove(s)}
                onStatusClick={(e) => {
                  e.preventDefault();
                  e.stopPropagation();
                  setStatusMenuFor((prev) => (prev === s.id ? null : s.id));
                }}
              />
              {statusMenuFor === s.id && (
                <div
                  ref={menuRef}
                  className="absolute right-12 top-1/2 -translate-y-1/2 z-20 rounded-xl pop-in py-1.5"
                  style={{
                    background: "var(--surface)",
                    border: "1px solid var(--border)",
                    boxShadow: "var(--shadow-lg)",
                  }}
                >
                  {ACTIVE_SPONSORSHIP_STATUSES.map((st) => (
                    <button
                      key={st}
                      onClick={() => changeStatus(s, st)}
                      className="w-full text-left px-4 py-2 text-xs font-semibold whitespace-nowrap transition-colors hover:bg-[var(--muted)] flex items-center gap-2"
                      style={{
                        color: st === s.status ? "var(--brand)" : "var(--text)",
                      }}
                    >
                      <Badge tone={STATUS_TONE[st]}>{SPONSORSHIP_STATUS_LABEL[st]}</Badge>
                      {st === s.status && (
                        <span className="ml-auto" style={{ color: "var(--brand)" }}>
                          ✓
                        </span>
                      )}
                    </button>
                  ))}
                </div>
              )}
            </li>
          ))}
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

function FilterChips({
  filter,
  onChange,
}: {
  filter: Filter;
  onChange: (f: Filter) => void;
}) {
  const chips: { value: Filter; label: string }[] = [
    { value: "all", label: "전체" },
    { value: "expiringSoon", label: "⏰ 마감 임박" },
    ...ACTIVE_SPONSORSHIP_STATUSES.map((s) => ({
      value: s,
      label: SPONSORSHIP_STATUS_LABEL[s],
    })),
  ];
  return (
    <div className="flex gap-1.5 overflow-x-auto pb-1 -mx-1 px-1">
      {chips.map((c) => {
        const active = filter === c.value;
        return (
          <button
            key={c.value}
            onClick={() => onChange(c.value)}
            className={`chip whitespace-nowrap transition-all ${active ? "chip-active" : ""}`}
          >
            {c.label}
          </button>
        );
      })}
    </div>
  );
}

function SponsorshipRow({
  item,
  isSelected,
  hasAnySelected,
  onToggleSelect,
  onTogglePin,
  onDelete,
  onStatusClick,
}: {
  item: Sponsorship;
  isSelected: boolean;
  hasAnySelected: boolean;
  onToggleSelect: () => void;
  onTogglePin: () => void;
  onDelete: () => void;
  onStatusClick: (e: React.MouseEvent) => void;
}) {
  const d = daysRemaining(item.end_date);
  const expired = isExpired(item.end_date);
  const dLabel = !item.end_date
    ? null
    : expired
      ? "마감됨"
      : d === 0
        ? "D-Day"
        : `D-${d}`;
  const dColor = expired
    ? "var(--text-tertiary)"
    : d <= 3
      ? "var(--warning)"
      : "var(--text-secondary)";

  return (
    <Card
      hover
      padding="md"
      className="flex items-center gap-3 group"
      style={
        isSelected
          ? { borderColor: "var(--brand)", background: "var(--brand-soft)" }
          : undefined
      }
    >
      <button
        onClick={onToggleSelect}
        className={`w-5 h-5 rounded flex items-center justify-center flex-shrink-0 transition-all ${
          isSelected || hasAnySelected ? "opacity-100" : "opacity-0 group-hover:opacity-100"
        }`}
        style={{
          background: isSelected ? "var(--brand)" : "transparent",
          border: isSelected ? "none" : "2px solid var(--border-strong)",
          color: "white",
        }}
        aria-label={isSelected ? "선택 해제" : "선택"}
      >
        {isSelected && (
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
            <polyline points="20 6 9 17 4 12" />
          </svg>
        )}
      </button>
      <button
        onClick={onTogglePin}
        className="text-lg leading-none flex-shrink-0"
        aria-label={item.is_pinned ? "고정 해제" : "고정"}
      >
        {item.is_pinned ? "📌" : <span className="opacity-30 hover:opacity-60">📍</span>}
      </button>
      <Link
        href={`/sponsorships/${item.id}`}
        className="flex-1 min-w-0 flex items-center gap-3 -my-2 py-2"
      >
        <Avatar name={item.brand_name} size={44} />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-0.5">
            <p className="text-sm font-bold truncate">{item.brand_name}</p>
            <button
              onClick={onStatusClick}
              className="cursor-pointer"
              aria-label="상태 변경"
              title="상태 변경"
            >
              <Badge tone={STATUS_TONE[item.status]}>
                {SPONSORSHIP_STATUS_LABEL[item.status]}{" "}
                <span style={{ opacity: 0.6 }}>▾</span>
              </Badge>
            </button>
          </div>
          {item.product_name && (
            <p className="text-xs truncate" style={{ color: "var(--text-secondary)" }}>
              {item.product_name}
            </p>
          )}
          <p className="text-[11px] mt-0.5 tabular" style={{ color: "var(--text-tertiary)" }}>
            {formatDate(item.start_date)} ~ {formatDate(item.end_date)}
          </p>
        </div>
        <div className="text-right flex-shrink-0">
          <p className="text-sm font-bold tabular">{formatKrw(item.amount)}</p>
          {dLabel && (
            <p
              className="text-[11px] mt-0.5 font-semibold tabular"
              style={{ color: dColor }}
            >
              {dLabel}
            </p>
          )}
        </div>
      </Link>
      <button
        onClick={() => {
          if (confirm(`${item.brand_name} 협찬을 삭제할까요? (5초 안에 되돌릴 수 있어요)`)) {
            onDelete();
          }
        }}
        className="opacity-0 group-hover:opacity-100 lg:opacity-100 text-base transition-opacity flex-shrink-0 w-7 h-7 flex items-center justify-center rounded-full hover:bg-[var(--danger-soft)]"
        aria-label="삭제"
        style={{ color: "var(--text-tertiary)" }}
      >
        ✕
      </button>
    </Card>
  );
}

const sortFn = (a: Sponsorship, b: Sponsorship) => {
  if (a.is_pinned !== b.is_pinned) return a.is_pinned ? -1 : 1;
  const ae = a.end_date ? new Date(a.end_date).getTime() : Infinity;
  const be = b.end_date ? new Date(b.end_date).getTime() : Infinity;
  return ae - be;
};
