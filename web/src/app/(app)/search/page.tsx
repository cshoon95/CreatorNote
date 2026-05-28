import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { SearchClient } from "./search-client";
import { PageHeader } from "@/components/ui/page-header";
import type { Sponsorship, ReelsNote, GeneralNote } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function SearchPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const wid = ctx!.workspace!.id;

  const [{ data: sponsors }, { data: reels }, { data: generals }] = await Promise.all([
    supabase.from("sponsorships").select("*").eq("workspace_id", wid),
    supabase.from("reels_notes").select("*").eq("workspace_id", wid),
    supabase.from("general_notes").select("*").eq("workspace_id", wid),
  ]);

  return (
    <div>
      <PageHeader title="검색" subtitle="협찬과 노트를 한 번에 검색해요" />
      <SearchClient
        sponsorships={(sponsors ?? []) as Sponsorship[]}
        reelsNotes={(reels ?? []) as ReelsNote[]}
        generalNotes={(generals ?? []) as GeneralNote[]}
      />
    </div>
  );
}
