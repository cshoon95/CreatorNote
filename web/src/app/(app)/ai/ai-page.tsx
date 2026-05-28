"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { PageHeader } from "@/components/ui/page-header";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { AiAssist } from "@/components/ai-assist";
import { useWorkspace } from "@/components/workspace-context";
import { createClient } from "@/lib/supabase/client";
import { toast } from "@/components/toast";

export function AiPage() {
  const router = useRouter();
  const ws = useWorkspace();
  const [lastResult, setLastResult] = useState<string>("");
  const [saving, setSaving] = useState(false);

  const saveAsNote = async (kind: "reels" | "general") => {
    if (!lastResult || saving) return;
    setSaving(true);
    const supabase = createClient();
    const table = kind === "reels" ? "reels_notes" : "general_notes";
    const firstLine = lastResult.split("\n").find((l) => l.trim()) ?? "AI 작성";
    const title = firstLine.slice(0, 40).replace(/^#+\s*/, "");
    const { data, error } = await supabase
      .from(table)
      .insert({
        workspace_id: ws.workspaceId,
        created_by: ws.userId,
        title,
        plain_content: lastResult,
      })
      .select()
      .single();
    setSaving(false);
    if (error || !data) {
      toast("저장 실패: " + (error?.message ?? ""), "danger");
      return;
    }
    toast("✨ 노트로 저장됨", "success");
    router.push(`/notes/${kind}/${data.id}`);
  };

  return (
    <div className="space-y-5">
      <PageHeader
        title="AI 어시스트"
        subtitle="Claude로 릴스 캡션·콘티·메일·해시태그를 한 번에"
      />

      <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_320px] gap-5">
        <Card padding="none" className="overflow-hidden" >
          <div style={{ height: "min(72vh, 800px)" }}>
            <AiAssistWithCapture onResult={setLastResult} />
          </div>
        </Card>

        <div className="space-y-3">
          <Card padding="md">
            <p className="text-sm font-bold mb-1">결과를 노트로 저장</p>
            <p className="text-[11px] mb-3" style={{ color: "var(--text-tertiary)" }}>
              생성된 텍스트를 바로 노트로 만듭니다
            </p>
            <div className="flex gap-2">
              <Button
                variant="secondary"
                size="sm"
                onClick={() => saveAsNote("reels")}
                disabled={!lastResult || saving}
                fullWidth
              >
                🎬 릴스 노트로
              </Button>
              <Button
                variant="secondary"
                size="sm"
                onClick={() => saveAsNote("general")}
                disabled={!lastResult || saving}
                fullWidth
              >
                📝 메모로
              </Button>
            </div>
          </Card>

          <Card padding="md">
            <p className="text-sm font-bold mb-2">💡 활용 팁</p>
            <ul
              className="text-xs space-y-1.5 leading-relaxed"
              style={{ color: "var(--text-secondary)" }}
            >
              <li>• &ldquo;최신&rdquo;·&ldquo;요즘&rdquo;·&ldquo;2026&rdquo; 등 시의성 키워드를 넣으면 자동으로 웹 검색</li>
              <li>• 본인 채널 톤·말투를 프롬프트에 넣으면 결과 품질↑</li>
              <li>• 노트 에디터 안에서 ✨ AI 버튼으로도 호출 가능</li>
              <li>• ⌘+↵ 로 빠르게 전송</li>
            </ul>
          </Card>

          <Card padding="md">
            <p className="text-sm font-bold mb-2">예시 프롬프트</p>
            <ul
              className="text-xs space-y-2"
              style={{ color: "var(--text-secondary)" }}
            >
              <li>· &ldquo;임산부 최신 정부 혜택 4가지 정리해서 릴스 캡션 작성. 친근한 톤, 해시태그 포함&rdquo;</li>
              <li>· &ldquo;30대 직장인 재테크 콘텐츠 해시태그 30개. 인기·중간·롱테일 비율로&rdquo;</li>
              <li>· &ldquo;협찬 단가 100만원 제안 받았는데 150만원으로 협상하는 정중한 메일&rdquo;</li>
              <li>· &ldquo;OO 브랜드 4월 정산 80만원 미입금. 정중한 follow-up 메일&rdquo;</li>
            </ul>
          </Card>
        </div>
      </div>
    </div>
  );
}

// Wrapper that exposes generated text so the right-side card can save it
function AiAssistWithCapture({ onResult }: { onResult: (text: string) => void }) {
  return <AiAssist initialKind="reels_script_adam" onInsert={onResult} />;
}
