import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { CalendarView } from "./calendar-view";
import { PageHeader } from "@/components/ui/page-header";
import type { Sponsorship } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function CalendarPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data } = await supabase
    .from("sponsorships")
    .select("*")
    .eq("workspace_id", ctx!.workspace!.id);
  const items = (data ?? []) as Sponsorship[];

  return (
    <div>
      <PageHeader title="캘린더" subtitle="협찬 일정 한눈에 보기" />
      <CalendarView items={items} />
    </div>
  );
}
