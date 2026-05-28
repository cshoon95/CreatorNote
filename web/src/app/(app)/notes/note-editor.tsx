"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useWorkspace } from "@/components/workspace-context";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";
import { uploadNoteImage, deleteNoteImages } from "@/lib/storage";
import { SignedImage, useSignedUrls } from "@/components/ui/signed-image";
import { TagInput } from "@/components/ui/tag-input";
import { AiAssist, type AiKind } from "@/components/ai-assist";
import {
  REELS_STATUS_LABEL,
  type GeneralNote,
  type ReelsNote,
  type ReelsNoteStatus,
  type Sponsorship,
} from "@/lib/types";

export type NoteKind = "reels" | "general";

interface NoteEditorProps {
  kind: NoteKind;
  initial?: ReelsNote | GeneralNote;
  sponsorships?: Pick<Sponsorship, "id" | "brand_name">[];
}

type SaveState = "idle" | "saving" | "saved" | "error";

export function NoteEditor({ kind, initial, sponsorships = [] }: NoteEditorProps) {
  const router = useRouter();
  const ws = useWorkspace();
  const fileRef = useRef<HTMLInputElement>(null);
  const isEdit = !!initial;
  const table = kind === "reels" ? "reels_notes" : "general_notes";
  const backHref = "/notes";

  const [title, setTitle] = useState(initial?.title ?? "");
  const [content, setContent] = useState(initial?.plain_content ?? "");
  const [tags, setTags] = useState<string[]>(initial?.tags ?? []);
  const [status, setStatus] = useState<ReelsNoteStatus>(
    (initial as ReelsNote | undefined)?.status ?? "drafting",
  );
  const [imageUrls, setImageUrls] = useState<string[]>(initial?.image_urls ?? []);
  const [isPinned, setIsPinned] = useState(initial?.is_pinned ?? false);
  const [sponsorshipId, setSponsorshipId] = useState<string | null>(
    (initial as ReelsNote | undefined)?.sponsorship_id ?? null,
  );
  const [busy, setBusy] = useState(false);
  const [saveState, setSaveState] = useState<SaveState>(isEdit ? "saved" : "idle");
  const [aiOpen, setAiOpen] = useState(false);

  // Batch-resolve signed URLs for all images at once (1 request vs N)
  const signedUrlMap = useSignedUrls(imageUrls);

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const firstRender = useRef(true);

  // Autosave (debounced 1.5s) for existing notes only
  useEffect(() => {
    if (!isEdit) return;
    if (firstRender.current) {
      firstRender.current = false;
      return;
    }
    if (debounceRef.current) clearTimeout(debounceRef.current);
    setSaveState("idle");
    debounceRef.current = setTimeout(() => {
      void doSave({ silent: true });
    }, 1500);
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [title, content, tags, status, imageUrls, isPinned, sponsorshipId]);

  const onAddImages = async (files: FileList | null) => {
    if (!files || files.length === 0) return;
    setBusy(true);
    try {
      const arr = Array.from(files);
      const results = await Promise.all(arr.map((f) => uploadNoteImage(ws.userId, f)));
      const uploaded = results.filter((p): p is string => Boolean(p));
      setImageUrls((cur) => [...cur, ...uploaded]);
      if (uploaded.length > 0) toast(`📸 ${uploaded.length}개 업로드됨`, "success");
      if (uploaded.length < arr.length) {
        toast(`${arr.length - uploaded.length}개 업로드 실패`, "warning");
      }
    } finally {
      setBusy(false);
    }
  };

  const removeImage = async (path: string) => {
    if (!confirm("이미지를 삭제할까요?")) return;
    setImageUrls((cur) => cur.filter((p) => p !== path));
    await deleteNoteImages([path]);
  };

  const doSave = async ({ silent }: { silent?: boolean } = {}) => {
    if (busy) return;
    setBusy(true);
    setSaveState("saving");
    try {
      const supabase = createClient();
      const base = {
        title: title.trim(),
        plain_content: content,
        tags,
        image_urls: imageUrls,
        is_pinned: isPinned,
      };
      const payload =
        kind === "reels"
          ? { ...base, status, sponsorship_id: sponsorshipId }
          : base;
      if (isEdit) {
        const { error } = await supabase
          .from(table)
          .update(payload)
          .eq("id", initial!.id)
          .eq("workspace_id", ws.workspaceId);
        if (error) {
          if (!silent) toast("저장 실패", "danger");
          setSaveState("error");
          return;
        }
        setSaveState("saved");
        if (!silent) toast("저장되었어요", "success");
      } else {
        const { data, error } = await supabase
          .from(table)
          .insert({ ...payload, workspace_id: ws.workspaceId, created_by: ws.userId })
          .select()
          .single();
        if (error || !data) {
          if (!silent) toast("생성 실패", "danger");
          setSaveState("error");
          return;
        }
        if (!silent) toast("✨ 노트 생성됨", "success");
        router.replace(`/notes/${kind}/${data.id}`);
        router.refresh();
        return;
      }
    } finally {
      setBusy(false);
    }
  };

  const remove = async () => {
    if (!isEdit) return;
    if (!confirm("이 노트를 삭제할까요?")) return;
    setBusy(true);
    const supabase = createClient();
    const { error } = await supabase.from(table).delete().eq("id", initial!.id);
    if (error) {
      toast("삭제 실패", "danger");
      setBusy(false);
      return;
    }
    if (imageUrls.length > 0) await deleteNoteImages(imageUrls);
    toast("삭제되었어요", "success");
    router.push(backHref);
    router.refresh();
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-5 gap-2">
        <button
          onClick={() => router.back()}
          className="text-sm whitespace-nowrap"
          style={{ color: "var(--text-secondary)" }}
        >
          ← 노트 목록
        </button>
        <div className="flex items-center gap-2 flex-wrap justify-end">
          {isEdit && <SaveIndicator state={saveState} />}
          <button
            onClick={() => setAiOpen(true)}
            className="chip chip-active"
            title="AI 어시스트"
          >
            ✨ AI
          </button>
          <button
            onClick={() => setIsPinned((v) => !v)}
            className="w-9 h-9 rounded-xl flex items-center justify-center transition-colors hover:bg-[var(--muted)]"
            aria-label={isPinned ? "고정 해제" : "고정"}
            title={isPinned ? "고정 해제" : "고정"}
          >
            <span style={{ opacity: isPinned ? 1 : 0.3 }}>📌</span>
          </button>
          {kind === "reels" && (
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value as ReelsNoteStatus)}
              className="chip"
              style={{ padding: "0.4rem 0.75rem", fontSize: "0.75rem" }}
            >
              {(["drafting", "readyToUpload", "uploaded"] as ReelsNoteStatus[]).map((s) => (
                <option key={s} value={s}>
                  {REELS_STATUS_LABEL[s]}
                </option>
              ))}
            </select>
          )}
          {kind === "reels" && sponsorships.length > 0 && (
            <select
              value={sponsorshipId ?? ""}
              onChange={(e) => setSponsorshipId(e.target.value || null)}
              className="chip"
              style={{ padding: "0.4rem 0.75rem", fontSize: "0.75rem", maxWidth: 180 }}
            >
              <option value="">🔗 협찬 연결 (선택)</option>
              {sponsorships.map((sp) => (
                <option key={sp.id} value={sp.id}>
                  🤝 {sp.brand_name}
                </option>
              ))}
            </select>
          )}
        </div>
      </div>

      <div
        className="card overflow-hidden"
        style={{ boxShadow: "var(--shadow-md)" }}
      >
        <div
          className="px-6 lg:px-8 pt-6 lg:pt-7 pb-3 border-b"
          style={{ borderColor: "var(--border)" }}
        >
          <input
            className="w-full bg-transparent text-3xl font-bold tracking-tight outline-none"
            placeholder="제목 없음"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
          />
        </div>

        {imageUrls.length > 0 && (
          <div
            className="px-6 lg:px-8 pt-5 pb-2 border-b"
            style={{ borderColor: "var(--border)" }}
          >
            <div className="grid grid-cols-3 sm:grid-cols-4 lg:grid-cols-5 gap-2.5">
              {imageUrls.map((path) => (
                <div
                  key={path}
                  className="relative aspect-square rounded-xl overflow-hidden group"
                  style={{ border: "1px solid var(--border)" }}
                >
                  <SignedImage path={path} url={signedUrlMap[path]} className="w-full h-full object-cover" />
                  <button
                    onClick={() => removeImage(path)}
                    className="absolute top-1.5 right-1.5 w-7 h-7 rounded-full bg-black/60 text-white text-xs flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                    aria-label="이미지 삭제"
                  >
                    ✕
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="px-6 lg:px-8 py-6">
          <textarea
            className="w-full bg-transparent outline-none min-h-[360px] text-[15px] leading-relaxed resize-y"
            placeholder={
              kind === "reels"
                ? "스크립트, 콘티, 해시태그, 노출 일정을 자유롭게 적어두세요"
                : "메모를 작성하세요"
            }
            value={content}
            onChange={(e) => setContent(e.target.value)}
          />
        </div>

        <div
          className="px-6 lg:px-8 py-4 border-t"
          style={{ borderColor: "var(--border)", background: "var(--bg)" }}
        >
          <p
            className="text-[11px] font-semibold mb-2"
            style={{ color: "var(--text-tertiary)" }}
          >
            태그
          </p>
          <TagInput tags={tags} onChange={setTags} />
        </div>
      </div>

      <div
        className="flex items-center gap-2 mt-5 pt-1"
      >
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          multiple
          hidden
          onChange={(e) => onAddImages(e.target.files)}
        />
        <Button
          variant="secondary"
          onClick={() => fileRef.current?.click()}
          disabled={busy}
          iconLeft={<span>🖼</span>}
        >
          이미지 추가
        </Button>
        <span className="flex-1" />
        {isEdit && (
          <Button variant="danger" onClick={remove} disabled={busy}>
            삭제
          </Button>
        )}
        <Button variant="primary" onClick={() => doSave()} loading={busy}>
          {isEdit ? "지금 저장" : "노트 생성"}
        </Button>
      </div>

      {aiOpen && (
        <div
          className="fixed inset-0 z-[110] flex items-stretch sm:items-center sm:justify-end pop-in"
          style={{ background: "rgba(15, 23, 42, 0.4)", backdropFilter: "blur(4px)" }}
          onClick={() => setAiOpen(false)}
        >
          <div
            className="w-full sm:max-w-md bg-[var(--surface)] sm:my-4 sm:mr-4 sm:rounded-2xl shadow-2xl flex flex-col"
            style={{ maxHeight: "calc(100vh - 2rem)", height: "100%", boxShadow: "var(--shadow-lg)" }}
            onClick={(e) => e.stopPropagation()}
          >
            <AiAssist
              initialKind={kind === "reels" ? "reels_script_adam" : "general"}
              onClose={() => setAiOpen(false)}
              onInsert={(text) => {
                setContent((cur) => (cur ? cur.trimEnd() + "\n\n" + text : text));
              }}
            />
          </div>
        </div>
      )}
    </div>
  );
}

// suppress unused
void (null as unknown as AiKind);

function SaveIndicator({ state }: { state: SaveState }) {
  const labels = {
    idle: { text: "변경됨", color: "var(--text-tertiary)", emoji: "•" },
    saving: { text: "저장 중...", color: "var(--text-tertiary)", emoji: "⏳" },
    saved: { text: "저장됨", color: "var(--success)", emoji: "✓" },
    error: { text: "저장 실패", color: "var(--danger)", emoji: "⚠️" },
  } as const;
  const cfg = labels[state];
  return (
    <span
      className="text-[11px] font-semibold flex items-center gap-1 px-2 py-1 rounded-md"
      style={{ color: cfg.color, background: "var(--muted)" }}
    >
      <span>{cfg.emoji}</span>
      {cfg.text}
    </span>
  );
}
