import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { NotesTabs } from "./notes-tabs";
import type { ReelsNote, GeneralNote } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function NotesPage() {
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const NOTES_LIMIT = 100;
  const [{ data: reels }, { data: generals }] = await Promise.all([
    supabase
      .from("reels_notes")
      .select("*")
      .eq("workspace_id", ctx!.workspace!.id)
      .order("is_pinned", { ascending: false })
      .order("updated_at", { ascending: false })
      .limit(NOTES_LIMIT),
    supabase
      .from("general_notes")
      .select("*")
      .eq("workspace_id", ctx!.workspace!.id)
      .order("is_pinned", { ascending: false })
      .order("updated_at", { ascending: false })
      .limit(NOTES_LIMIT),
  ]);

  return (
    <NotesTabs
      reelsNotes={(reels ?? []) as ReelsNote[]}
      generalNotes={(generals ?? []) as GeneralNote[]}
    />
  );
}
