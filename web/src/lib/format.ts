export function formatKrw(amount: number | null | undefined): string {
  if (amount == null) return "₩0";
  const value = Math.round(amount);
  return "₩" + value.toLocaleString("ko-KR");
}

export function formatKrwShort(amount: number | null | undefined): string {
  if (amount == null) return "₩0";
  const v = Math.round(amount);
  if (v >= 100_000_000) return `₩${(v / 100_000_000).toFixed(1)}억`;
  if (v >= 10_000) return `₩${(v / 10_000).toFixed(0)}만`;
  return formatKrw(v);
}

export function formatDate(value: string | Date | null | undefined): string {
  if (!value) return "—";
  const d = new Date(value);
  return d.toLocaleDateString("ko-KR", { year: "numeric", month: "2-digit", day: "2-digit" });
}

export function formatDateShort(value: string | Date | null | undefined): string {
  if (!value) return "—";
  const d = new Date(value);
  return d.toLocaleDateString("ko-KR", { month: "2-digit", day: "2-digit" });
}

export function formatDateTime(value: string | Date | null | undefined): string {
  if (!value) return "—";
  const d = new Date(value);
  return d.toLocaleString("ko-KR", {
    year: "2-digit", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit",
  });
}

export function toIsoDate(value: Date | string): string {
  const d = typeof value === "string" ? new Date(value) : value;
  return d.toISOString().slice(0, 10);
}

export function daysBetween(from: Date | string, to: Date | string): number {
  const a = typeof from === "string" ? new Date(from) : from;
  const b = typeof to === "string" ? new Date(to) : to;
  const ms = b.getTime() - a.getTime();
  return Math.round(ms / 86_400_000);
}

export function daysRemaining(endDate: string | null | undefined): number {
  if (!endDate) return 0;
  return daysBetween(new Date(), endDate);
}

export function isExpired(endDate: string | null | undefined): boolean {
  if (!endDate) return false;
  return new Date(endDate) < new Date();
}
