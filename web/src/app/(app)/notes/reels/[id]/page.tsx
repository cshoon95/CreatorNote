import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { NoteEditor } from "../../note-editor";
import type { ReelsNote, Sponsorship } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function ReelsNoteDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const wid = ctx!.workspace!.id;
  const [{ data: note }, { data: sponsors }] = await Promise.all([
    supabase.from("reels_notes").select("*").eq("workspace_id", wid).eq("id", id).maybeSingle(),
    supabase
      .from("sponsorships")
      .select("id, brand_name")
      .eq("workspace_id", wid)
      .order("created_at", { ascending: false }),
  ]);
  if (!note) notFound();
  return (
    <NoteEditor
      kind="reels"
      initial={note as ReelsNote}
      sponsorships={(sponsors ?? []) as Pick<Sponsorship, "id" | "brand_name">[]}
    />
  );
}
