import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { NoteEditor } from "../../note-editor";
import type { Sponsorship } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function NewReelsNotePage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data } = await supabase
    .from("sponsorships")
    .select("id, brand_name")
    .eq("workspace_id", ctx!.workspace!.id)
    .order("created_at", { ascending: false });
  return (
    <NoteEditor
      kind="reels"
      sponsorships={(data ?? []) as Pick<Sponsorship, "id" | "brand_name">[]}
    />
  );
}
