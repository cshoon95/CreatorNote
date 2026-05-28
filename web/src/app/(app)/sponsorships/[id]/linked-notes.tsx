"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Modal } from "@/components/ui/modal";
import { ReelsBadge } from "@/components/ui/status-badge";
import { toast } from "@/components/toast";
import { useWorkspace } from "@/components/workspace-context";
import type { ReelsNote } from "@/lib/types";

interface LinkedNotesSectionProps {
  sponsorshipId: string;
  linkedNotes: ReelsNote[];
  unassignedNotes: ReelsNote[]; // notes not yet linked (or already linked to this one)
}

export function LinkedNotesSection({
  sponsorshipId,
  linkedNotes,
  unassignedNotes,
}: LinkedNotesSectionProps) {
  const router = useRouter();
  const ws = useWorkspace();
  const [pickerOpen, setPickerOpen] = useState(false);

  const linkNote = async (noteId: string) => {
    const supabase = createClient();
    const { error } = await supabase
      .from("reels_notes")
      .update({ sponsorship_id: sponsorshipId })
      .eq("id", noteId)
      .eq("workspace_id", ws.workspaceId);
    if (error) {
      toast("연결 실패", "danger");
      return;
    }
    toast("🔗 노트가 연결되었어요", "success");
    setPickerOpen(false);
    router.refresh();
  };

  const unlinkNote = async (noteId: string) => {
    if (!confirm("이 노트의 협찬 연결을 해제할까요?")) return;
    const supabase = createClient();
    const { error } = await supabase
      .from("reels_notes")
      .update({ sponsorship_id: null })
      .eq("id", noteId)
      .eq("workspace_id", ws.workspaceId);
    if (error) {
      toast("해제 실패", "danger");
      return;
    }
    toast("연결 해제됨", "info");
    router.refresh();
  };

  const createAndLink = async () => {
    const supabase = createClient();
    const { data, error } = await supabase
      .from("reels_notes")
      .insert({
        workspace_id: ws.workspaceId,
        created_by: ws.userId,
        sponsorship_id: sponsorshipId,
        title: "",
      })
      .select()
      .single();
    if (error || !data) {
      toast("생성 실패", "danger");
      return;
    }
    setPickerOpen(false);
    router.push(`/notes/reels/${data.id}`);
  };

  const availableToLink = unassignedNotes.filter((n) => n.sponsorship_id !== sponsorshipId);

  return (
    <section className="mt-4">
      <div className="flex items-center justify-between mb-2 px-1">
        <h3 className="text-sm font-bold flex items-center gap-2">
          <span>🎬</span>
          연결된 릴스 노트 {linkedNotes.length > 0 && `(${linkedNotes.length})`}
        </h3>
        <button
          onClick={() => setPickerOpen(true)}
          className="text-xs font-semibold"
          style={{ color: "var(--brand)" }}
        >
          + 추가
        </button>
      </div>
      {linkedNotes.length === 0 ? (
        <Card padding="md" className="text-center">
          <p className="text-xs py-2" style={{ color: "var(--text-tertiary)" }}>
            연결된 노트가 없어요. <button onClick={() => setPickerOpen(true)} className="underline" style={{ color: "var(--brand)" }}>추가</button>해 보세요.
          </p>
        </Card>
      ) : (
        <ul className="space-y-2">
          {linkedNotes.map((n) => (
            <li key={n.id} className="group">
              <Card hover padding="md" className="flex items-center gap-3">
                <Link href={`/notes/reels/${n.id}`} className="flex-1 min-w-0 -my-1 py-1">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-bold truncate">{n.title || "제목 없음"}</p>
                    <ReelsBadge status={n.status} />
                  </div>
                  <p className="text-xs truncate" style={{ color: "var(--text-secondary)" }}>
                    {n.plain_content || "내용 없음"}
                  </p>
                </Link>
                <button
                  onClick={() => unlinkNote(n.id)}
                  className="opacity-0 group-hover:opacity-100 lg:opacity-100 text-xs px-2 py-1 rounded transition-opacity"
                  style={{ color: "var(--text-tertiary)" }}
                  aria-label="연결 해제"
                >
                  해제
                </button>
              </Card>
            </li>
          ))}
        </ul>
      )}

      <Modal open={pickerOpen} onClose={() => setPickerOpen(false)} title="노트 연결">
        <div className="space-y-2">
          <Button variant="primary" fullWidth onClick={createAndLink} iconLeft={<span>✨</span>}>
            새 노트 만들고 연결
          </Button>
          {availableToLink.length > 0 && (
            <>
              <p className="text-[11px] font-semibold mt-4 mb-1" style={{ color: "var(--text-secondary)" }}>
                기존 노트 연결
              </p>
              <ul
                className="space-y-1.5 max-h-64 overflow-y-auto rounded-xl p-1"
                style={{ background: "var(--muted)" }}
              >
                {availableToLink.map((n) => (
                  <li key={n.id}>
                    <button
                      onClick={() => linkNote(n.id)}
                      className="w-full text-left rounded-lg px-3 py-2 transition-colors hover:bg-[var(--surface)]"
                    >
                      <p className="text-sm font-semibold truncate">
                        {n.title || "제목 없음"}
                      </p>
                      <p
                        className="text-[11px] truncate"
                        style={{ color: "var(--text-tertiary)" }}
                      >
                        {n.plain_content || "내용 없음"}
                      </p>
                    </button>
                  </li>
                ))}
              </ul>
            </>
          )}
        </div>
      </Modal>
    </section>
  );
}
