"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { toast } from "@/components/toast";

export type AiKind =
  | "reels_script_adam"
  | "reels_tease"
  | "reels_caption"
  | "reels_script"
  | "hashtags"
  | "email_reply"
  | "follow_up_payment"
  | "research"
  | "general";

// System instructions kept in sync with /api/ai/draft/route.ts so the prompts
// users copy into claude.ai produce the same quality as the API would.
const SYSTEM_PROMPTS: Record<AiKind, string> = {
  reels_script_adam: `당신은 한국 인플루언서의 릴스 영상 대본 작가입니다.
출력 조건:
- ElevenLabs Adam 음성 + 1.5배속 재생을 가정
- 분량: 정확히 20~30초 (한국어 기준 200~300자, 공백 포함)
- 구조: (1) 첫 2초 강한 후킹 → (2) 핵심 메시지 → (3) 마지막 CTA / 한 줄 임팩트
- 화자가 실제 말로 읽을 수 있는 자연스러운 구어체. 너무 긴 문장 금지
- 줄바꿈은 문장 호흡 단위로
- '컷', '클로즈업' 같은 연출 지시문 금지. 순수 발화 대본만
- 끝에 '예상 분량: OO자 / 약 ~초'를 한 줄로 표기`,
  reels_tease: `당신은 정보 제공형 릴스 콘텐츠 전략가입니다. 시청자가 더 알고 싶어서 캡션을 누르게 만드는 '티저' 컨셉으로 작성합니다.

반드시 다음 두 섹션을 그대로 출력하세요:

═══ 🎬 영상 대본 (Adam · 1.5x · 20~30초 / 200~300자) ═══
- 후킹 한 줄 + 가장 충격적이거나 호기심을 자극하는 정보 1~2개만 노출
- 모든 정보를 다 풀지 말 것 (티저니까!)
- 마지막은 반드시 "👇 자세한 정보는 캡션 확인!" 또는 유사한 CTA
- 끝에 '예상 분량: OO자 / 약 ~초' 한 줄

═══ 📝 캡션 (전체 정보 풀버전) ═══
- 영상에서 생략한 모든 디테일을 친절하게 정리
- 번호 매기기, 이모지, 줄바꿈으로 스캔 가능한 형식
- 출처가 있다면 마지막에 명시
- 관련 해시태그 8~15개 자연스럽게 부착

최신/요즘/2026 등 시의성이 필요한 주제라면 반드시 웹 검색을 사용하세요.`,
  reels_caption:
    "당신은 한국 인플루언서의 릴스 캡션을 작성하는 전문가입니다. 짧고 흡인력 있는 문장, 적절한 이모지, 마지막에 해시태그 8~15개를 자연스럽게 붙입니다.",
  reels_script:
    "당신은 릴스/숏폼 콘티 작가입니다. 도입(2초)·전개·반전·CTA 구조로 30-60초 분량 한국어 영상 스크립트와 자막을 작성합니다.",
  hashtags:
    "당신은 인스타그램 SEO 전문가입니다. 주제와 관련된 한국 시장에서 실제로 검색되는 해시태그 30개를 인기·중간·롱테일 비율로 균형 있게 추천하세요. 출력 형식은 '#태그' 단일 라인.",
  email_reply:
    "당신은 한국 인플루언서를 위한 비즈니스 이메일 작성자입니다. 정중하고 전문적이면서도 따뜻한 톤. 가격·일정·결과물 범위를 명확히 협의하는 방향.",
  follow_up_payment:
    "당신은 인플루언서 정산 미수금 독촉 메일을 작성합니다. 정중하고 부담스럽지 않게, 정산일과 금액을 명시하고 후속 일정을 요청합니다.",
  research:
    "당신은 정보 리서치 전문가입니다. 한국 사용자를 위해 사실에 근거해 최신 정보를 정확하게 요약합니다. 시의성 있는 주제는 반드시 웹 검색을 사용해 최신 정보를 가져오세요.",
  general:
    "당신은 한국 인플루언서를 돕는 AI 어시스턴트입니다. 사용자의 요청에 맞게 자연스럽고 실용적인 한국어 문장을 작성합니다.",
};

export const PRESETS: { kind: AiKind; label: string; emoji: string; example: string }[] = [
  {
    kind: "reels_script_adam",
    label: "릴스 대본 (Adam·1.5x·20~30s)",
    emoji: "🎙",
    example: "MZ 직장인 점심값 아끼는 5가지 팁",
  },
  {
    kind: "reels_tease",
    label: "정보 릴스 (티저+캡션)",
    emoji: "🪝",
    example: "임산부 최신 정부 혜택 5가지 알려주는 정보 릴스",
  },
  {
    kind: "reels_caption",
    label: "릴스 캡션",
    emoji: "📝",
    example: "신상 카페 방문 후기 릴스 캡션",
  },
  {
    kind: "reels_script",
    label: "릴스 콘티 (일반)",
    emoji: "🎬",
    example: "신혼부부 5초 hook + 30초 콘티",
  },
  {
    kind: "hashtags",
    label: "해시태그 30개",
    emoji: "🏷",
    example: "30대 직장인 재테크 콘텐츠",
  },
  {
    kind: "email_reply",
    label: "협찬 메일 답변",
    emoji: "💌",
    example: "단가 협상 답장 (제안가 70만 → 100만 요청)",
  },
  {
    kind: "follow_up_payment",
    label: "정산 독촉 메일",
    emoji: "💸",
    example: "5월 15일 정산 예정 30만원, 아직 미입금",
  },
  {
    kind: "research",
    label: "정보 리서치",
    emoji: "🔎",
    example: "임산부 최신 정부 혜택 정리",
  },
  {
    kind: "general",
    label: "자유 작성",
    emoji: "✨",
    example: "내 채널 소개 한 문장 5개",
  },
];

interface AiAssistProps {
  onInsert?: (text: string) => void;
  onClose?: () => void;
  initialKind?: AiKind;
}

export function AiAssist({ onInsert, onClose, initialKind = "reels_script_adam" }: AiAssistProps) {
  const [kind, setKind] = useState<AiKind>(initialKind);
  const [topic, setTopic] = useState("");
  const [result, setResult] = useState("");

  const preset = PRESETS.find((p) => p.kind === kind)!;

  const fullPrompt =
    SYSTEM_PROMPTS[kind] +
    "\n\n---\n\n사용자 요청:\n" +
    (topic.trim() || `[여기에 요청을 입력하세요. 예: ${preset.example}]`);

  const safeCopy = async (text: string): Promise<boolean> => {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch {
      return false;
    }
  };

  const copyPrompt = async () => {
    if (!topic.trim()) {
      toast("주제를 먼저 입력해 주세요", "warning");
      return;
    }
    const ok = await safeCopy(fullPrompt);
    toast(ok ? "📋 프롬프트 복사 완료. claude.ai에 붙여넣으세요" : "복사 실패 — 브라우저 권한 확인", ok ? "success" : "danger");
  };

  const openClaude = async () => {
    if (!topic.trim()) {
      toast("주제를 먼저 입력해 주세요", "warning");
      return;
    }
    const ok = await safeCopy(fullPrompt);
    window.open("https://claude.ai/new", "_blank", "noopener");
    toast(ok ? "📋 복사됨 → claude.ai에서 ⌘V 후 Enter" : "claude.ai 열림 (수동 복사 필요)", ok ? "success" : "warning");
  };

  const insertResult = () => {
    if (!result.trim()) {
      toast("결과를 붙여넣어 주세요", "warning");
      return;
    }
    onInsert?.(result.trim());
    toast("본문에 삽입됨", "success");
    onClose?.();
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div
        className="flex items-center justify-between px-5 py-4 border-b"
        style={{ borderColor: "var(--border)" }}
      >
        <div className="flex items-center gap-2">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center text-base"
            style={{ background: "var(--brand-soft)" }}
          >
            ✨
          </div>
          <div>
            <p className="text-sm font-bold">AI 어시스트</p>
            <p className="text-[11px]" style={{ color: "var(--text-tertiary)" }}>
              프롬프트 생성 → claude.ai → 결과 붙여넣기
            </p>
          </div>
        </div>
        {onClose && (
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full flex items-center justify-center text-base hover:bg-[var(--muted)]"
            style={{ color: "var(--text-tertiary)" }}
            aria-label="닫기"
          >
            ✕
          </button>
        )}
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto">
        {/* Step 1: Preset */}
        <div className="px-5 py-4 border-b" style={{ borderColor: "var(--border)" }}>
          <p
            className="text-[11px] font-bold mb-2 flex items-center gap-1.5"
            style={{ color: "var(--text-tertiary)" }}
          >
            <Step n={1} /> 무엇을 도와드릴까요?
          </p>
          <div className="flex flex-wrap gap-1.5">
            {PRESETS.map((p) => {
              const active = kind === p.kind;
              return (
                <button
                  key={p.kind}
                  onClick={() => setKind(p.kind)}
                  className={`chip ${active ? "chip-active" : ""}`}
                >
                  <span>{p.emoji}</span>
                  {p.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Step 2: Topic */}
        <div className="px-5 py-4 border-b" style={{ borderColor: "var(--border)" }}>
          <p
            className="text-[11px] font-bold mb-2 flex items-center gap-1.5"
            style={{ color: "var(--text-tertiary)" }}
          >
            <Step n={2} /> 어떤 주제로?
          </p>
          <textarea
            value={topic}
            onChange={(e) => setTopic(e.target.value)}
            rows={2}
            className="input resize-none"
            placeholder={`예: ${preset.example}`}
          />
          <div className="flex gap-2 mt-3">
            <Button
              variant="secondary"
              onClick={copyPrompt}
              iconLeft={<span>📋</span>}
              fullWidth
            >
              프롬프트 복사
            </Button>
            <Button
              variant="primary"
              onClick={openClaude}
              iconLeft={<span>🚀</span>}
              fullWidth
            >
              claude.ai 열기
            </Button>
          </div>
          <p className="text-[10px] mt-2" style={{ color: "var(--text-tertiary)" }}>
            💡 &quot;claude.ai 열기&quot; 누르면 자동 복사 + 새 탭으로 열림. 거기서{" "}
            <kbd className="font-mono">⌘V</kbd> +{" "}
            <kbd className="font-mono">↵</kbd>
          </p>
        </div>

        {/* Step 3: Paste result */}
        <div className="px-5 py-4">
          <p
            className="text-[11px] font-bold mb-2 flex items-center gap-1.5"
            style={{ color: "var(--text-tertiary)" }}
          >
            <Step n={3} /> claude.ai 결과를 여기에 붙여넣기
          </p>
          <textarea
            value={result}
            onChange={(e) => setResult(e.target.value)}
            rows={8}
            className="input resize-none text-[13px] leading-relaxed"
            placeholder="claude.ai에서 받은 응답을 ⌘V로 붙여넣으세요"
          />
        </div>
      </div>

      {/* Actions */}
      <div
        className="px-5 py-3 border-t flex gap-2"
        style={{ borderColor: "var(--border)", background: "var(--bg)" }}
      >
        <Button
          variant="secondary"
          onClick={async () => {
            const ok = await safeCopy(result);
            toast(ok ? "📋 결과 복사됨" : "복사 실패", ok ? "success" : "danger");
          }}
          iconLeft={<span>📋</span>}
          disabled={!result}
          fullWidth
        >
          결과 복사
        </Button>
        {onInsert && (
          <Button
            variant="primary"
            onClick={insertResult}
            iconLeft={<span>✏️</span>}
            disabled={!result}
            fullWidth
          >
            본문에 삽입
          </Button>
        )}
      </div>
    </div>
  );
}

function Step({ n }: { n: number }) {
  return (
    <span
      className="w-4 h-4 rounded-full inline-flex items-center justify-center text-[9px] font-bold"
      style={{ background: "var(--brand)", color: "white" }}
    >
      {n}
    </span>
  );
}
