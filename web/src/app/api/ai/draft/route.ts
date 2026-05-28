import Anthropic from "@anthropic-ai/sdk";
import { createClient } from "@/lib/supabase/server";

export const runtime = "nodejs";
export const maxDuration = 60;

// Preset kinds → system instructions
const PRESETS: Record<string, string> = {
  reels_caption:
    "당신은 한국 인플루언서의 릴스 캡션을 작성하는 전문가입니다. 짧고 흡인력 있는 문장, 적절한 이모지, 마지막에 해시태그 8~15개를 자연스럽게 붙입니다.",
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

웹 검색이 필요한 주제(혜택·정책·최신 정보)는 반드시 web_search 사용.`,
  reels_script:
    "당신은 릴스/숏폼 콘티 작가입니다. 도입(2초)·전개·반전·CTA 구조로 30-60초 분량 한국어 영상 스크립트와 자막을 작성합니다.",
  hashtags:
    "당신은 인스타그램 SEO 전문가입니다. 주제와 관련된 한국 시장에서 실제로 검색되는 해시태그 30개를 인기·중간·롱테일 비율로 균형 있게 추천하세요. 출력 형식은 '#태그' 단일 라인.",
  email_reply:
    "당신은 한국 인플루언서를 위한 비즈니스 이메일 작성자입니다. 정중하고 전문적이면서도 따뜻한 톤. 가격·일정·결과물 범위를 명확히 협의하는 방향.",
  follow_up_payment:
    "당신은 인플루언서 정산 미수금 독촉 메일을 작성합니다. 정중하고 부담스럽지 않게, 정산일과 금액을 명시하고 후속 일정을 요청합니다.",
  research:
    "당신은 정보 리서치 전문가입니다. 한국 사용자를 위해 사실에 근거해 최신 정보를 정확하게 요약합니다. 필요하면 웹 검색을 사용하세요.",
  general:
    "당신은 한국 인플루언서를 돕는 AI 어시스턴트입니다. 사용자의 요청에 맞게 자연스럽고 실용적인 한국어 문장을 작성합니다.",
};

const BASE_SYSTEM = `당신은 'Influe'라는 크리에이터 워크스페이스의 AI 어시스턴트입니다.
한국 인플루언서를 돕는 것이 목적입니다. 항상 한국어로, 자연스럽고 실용적이며 간결하게 답하세요.
사용자의 요청이 "최신"·"요즘"·"지금"·"2026" 등 시의성이 필요한 정보라면 반드시 web_search 도구를 사용하세요.
출력은 그대로 복사/붙여넣기에 쓸 수 있게 정돈된 형식이어야 합니다.`;

export async function POST(request: Request) {
  // Auth gate
  const supabase = await createClient();
  const { data: userData } = await supabase.auth.getUser();
  if (!userData.user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const body = (await request.json().catch(() => ({}))) as {
    prompt?: string;
    kind?: keyof typeof PRESETS;
    history?: { role: "user" | "assistant"; content: string }[];
  };

  // Input validation — prevent abuse (huge payloads → Anthropic billing DoS)
  const MAX_PROMPT = 4000;
  const MAX_HISTORY_ITEMS = 10;
  const MAX_HISTORY_ITEM_CHARS = 2000;

  if (!body.prompt || !body.prompt.trim()) {
    return new Response(JSON.stringify({ error: "prompt required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
  if (body.prompt.length > MAX_PROMPT) {
    return new Response(
      JSON.stringify({ error: `prompt too long (max ${MAX_PROMPT} chars)` }),
      { status: 400, headers: { "Content-Type": "application/json" } },
    );
  }
  if (body.history) {
    if (!Array.isArray(body.history) || body.history.length > MAX_HISTORY_ITEMS) {
      return new Response(
        JSON.stringify({ error: `history must be array of ≤${MAX_HISTORY_ITEMS}` }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }
    for (const m of body.history) {
      if (
        !m ||
        (m.role !== "user" && m.role !== "assistant") ||
        typeof m.content !== "string" ||
        m.content.length > MAX_HISTORY_ITEM_CHARS
      ) {
        return new Response(
          JSON.stringify({ error: "invalid history item" }),
          { status: 400, headers: { "Content-Type": "application/json" } },
        );
      }
    }
  }

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "AI not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const client = new Anthropic({ apiKey });

  const kindInstruction = body.kind ? PRESETS[body.kind] ?? PRESETS.general : PRESETS.general;
  const system = [
    {
      type: "text" as const,
      text: BASE_SYSTEM,
      cache_control: { type: "ephemeral" as const },
    },
    { type: "text" as const, text: kindInstruction },
  ];

  const messages: Anthropic.MessageParam[] = [
    ...(body.history?.slice(-10) ?? []).map((m) => ({
      role: m.role,
      content: m.content,
    })),
    { role: "user" as const, content: body.prompt.trim() },
  ];

  const encoder = new TextEncoder();
  const readable = new ReadableStream({
    async start(controller) {
      const send = (obj: Record<string, unknown>) => {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(obj)}\n\n`));
      };
      try {
        const stream = client.messages.stream({
          model: "claude-sonnet-4-5",
          max_tokens: 2048,
          system,
          messages,
          tools: [
            {
              type: "web_search_20250305",
              name: "web_search",
              max_uses: 4,
            },
          ],
        });

        for await (const event of stream) {
          if (event.type === "content_block_start") {
            const block = event.content_block;
            if (block.type === "server_tool_use" && block.name === "web_search") {
              send({ type: "search_start" });
            }
          } else if (event.type === "content_block_delta") {
            if (event.delta.type === "text_delta") {
              send({ type: "text", text: event.delta.text });
            }
          } else if (event.type === "content_block_stop") {
            // pass-through
          } else if (event.type === "message_stop") {
            send({ type: "done" });
          }
        }
        controller.close();
      } catch (e) {
        const msg = e instanceof Error ? e.message : String(e);
        send({ type: "error", error: msg });
        controller.close();
      }
    },
  });

  return new Response(readable, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-store",
      Connection: "keep-alive",
    },
  });
}
