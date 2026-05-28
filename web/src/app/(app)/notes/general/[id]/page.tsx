import { notFound } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { getAuthContext } from "@/lib/auth";
import { NoteEditor } from "../../note-editor";
import type { GeneralNote } from "@/lib/types";

export const dynamic = "force-dynamic";

export default async function GeneralNoteDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const ctx = await getAuthContext();
  const supabase = await createClient();
  const { data } = await supabase
    .from("general_notes")
    .select("*")
    .eq("workspace_id", ctx!.workspace!.id)
    .eq("id", id)
    .maybeSingle();
  if (!data) notFound();
  return <NoteEditor kind="general" initial={data as GeneralNote} />;
}
