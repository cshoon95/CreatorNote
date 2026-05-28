import SwiftUI

/// Mirrors the web /ai assistant flow:
/// 1) Preset → 2) Topic → claude.ai 열기 → 3) 결과 붙여넣기 → 본문에 삽입.
/// API 콜이 없으므로 Claude Max 플랜으로 무료 사용 가능.
struct AiAssistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager

    enum AiKind: String, CaseIterable, Identifiable {
        case reelsScriptAdam
        case reelsTease
        case reelsCaption
        case hashtags
        case emailReply
        case followUpPayment
        case research
        case general

        var id: String { rawValue }

        var label: String {
            switch self {
            case .reelsScriptAdam: return "릴스 대본 (Adam·1.5x·20~30s)"
            case .reelsTease: return "정보 릴스 (티저+캡션)"
            case .reelsCaption: return "릴스 캡션"
            case .hashtags: return "해시태그 30개"
            case .emailReply: return "협찬 메일 답변"
            case .followUpPayment: return "정산 독촉 메일"
            case .research: return "정보 리서치"
            case .general: return "자유 작성"
            }
        }

        var emoji: String {
            switch self {
            case .reelsScriptAdam: return "🎙"
            case .reelsTease: return "🪝"
            case .reelsCaption: return "📝"
            case .hashtags: return "🏷"
            case .emailReply: return "💌"
            case .followUpPayment: return "💸"
            case .research: return "🔎"
            case .general: return "✨"
            }
        }

        var example: String {
            switch self {
            case .reelsScriptAdam: return "MZ 직장인 점심값 아끼는 5가지 팁"
            case .reelsTease: return "임산부 최신 정부 혜택 5가지 알려주는 정보 릴스"
            case .reelsCaption: return "신상 카페 방문 후기 릴스 캡션"
            case .hashtags: return "30대 직장인 재테크 콘텐츠"
            case .emailReply: return "단가 협상 답장 (제안가 70만 → 100만 요청)"
            case .followUpPayment: return "5월 15일 정산 예정 30만원, 아직 미입금"
            case .research: return "임산부 최신 정부 혜택 정리"
            case .general: return "내 채널 소개 한 문장 5개"
            }
        }

        var systemPrompt: String {
            switch self {
            case .reelsScriptAdam:
                return """
                당신은 한국 인플루언서의 릴스 영상 대본 작가입니다.
                출력 조건:
                - ElevenLabs Adam 음성 + 1.5배속 재생을 가정
                - 분량: 정확히 20~30초 (한국어 기준 200~300자, 공백 포함)
                - 구조: (1) 첫 2초 강한 후킹 → (2) 핵심 메시지 → (3) 마지막 CTA / 한 줄 임팩트
                - 화자가 실제 말로 읽을 수 있는 자연스러운 구어체. 너무 긴 문장 금지
                - 줄바꿈은 문장 호흡 단위로
                - '컷', '클로즈업' 같은 연출 지시문 금지. 순수 발화 대본만
                - 끝에 '예상 분량: OO자 / 약 ~초'를 한 줄로 표기
                """
            case .reelsTease:
                return """
                당신은 정보 제공형 릴스 콘텐츠 전략가입니다. 시청자가 더 알고 싶어서 캡션을 누르게 만드는 '티저' 컨셉으로 작성합니다.

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

                최신/요즘/2026 등 시의성이 필요한 주제라면 반드시 웹 검색을 사용하세요.
                """
            case .reelsCaption:
                return "당신은 한국 인플루언서의 릴스 캡션을 작성하는 전문가입니다. 짧고 흡인력 있는 문장, 적절한 이모지, 마지막에 해시태그 8~15개를 자연스럽게 붙입니다."
            case .hashtags:
                return "당신은 인스타그램 SEO 전문가입니다. 주제와 관련된 한국 시장에서 실제로 검색되는 해시태그 30개를 인기·중간·롱테일 비율로 균형 있게 추천하세요. 출력 형식은 '#태그' 단일 라인."
            case .emailReply:
                return "당신은 한국 인플루언서를 위한 비즈니스 이메일 작성자입니다. 정중하고 전문적이면서도 따뜻한 톤. 가격·일정·결과물 범위를 명확히 협의하는 방향."
            case .followUpPayment:
                return "당신은 인플루언서 정산 미수금 독촉 메일을 작성합니다. 정중하고 부담스럽지 않게, 정산일과 금액을 명시하고 후속 일정을 요청합니다."
            case .research:
                return "당신은 정보 리서치 전문가입니다. 한국 사용자를 위해 사실에 근거해 최신 정보를 정확하게 요약합니다. 시의성 있는 주제는 반드시 웹 검색을 사용해 최신 정보를 가져오세요."
            case .general:
                return "당신은 한국 인플루언서를 돕는 AI 어시스턴트입니다. 사용자의 요청에 맞게 자연스럽고 실용적인 한국어 문장을 작성합니다."
            }
        }
    }

    @State private var kind: AiKind
    @State private var topic: String = ""
    @State private var result: String = ""
    @State private var copyConfirm: String? = nil

    /// Called when user taps "본문에 삽입". Sheet dismisses afterwards.
    let onInsert: (String) -> Void

    init(initialKind: AiKind = .reelsScriptAdam, onInsert: @escaping (String) -> Void) {
        self._kind = State(initialValue: initialKind)
        self.onInsert = onInsert
    }

    private var fullPrompt: String {
        let placeholder = "[여기에 요청을 입력하세요. 예: \(kind.example)]"
        let userPart = topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? placeholder : topic
        return kind.systemPrompt + "\n\n---\n\n사용자 요청:\n" + userPart
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Step 1: Preset
                    stepHeader(n: 1, title: "무엇을 도와드릴까요?", theme: theme)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AiKind.allCases) { k in
                                Button {
                                    Haptic.selection()
                                    kind = k
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(k.emoji)
                                        Text(k.label)
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(kind == k ? theme.primary.opacity(0.15) : theme.cardBackground)
                                    .foregroundStyle(kind == k ? theme.primary : theme.textSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 999)
                                            .stroke(kind == k ? theme.primary.opacity(0.3) : theme.textSecondary.opacity(0.15), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }

                    // Step 2: Topic
                    stepHeader(n: 2, title: "어떤 주제로?", theme: theme)
                    ZStack(alignment: .topLeading) {
                        if topic.isEmpty {
                            Text("예: \(kind.example)")
                                .foregroundStyle(theme.textSecondary.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $topic)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 70)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.textSecondary.opacity(0.15), lineWidth: 1)
                    )

                    HStack(spacing: 8) {
                        Button {
                            copyToClipboard(fullPrompt)
                            copyConfirm = "📋 프롬프트 복사 완료"
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                Text("프롬프트 복사")
                            }
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.cardBackground)
                            .foregroundStyle(theme.textPrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        Button {
                            copyToClipboard(fullPrompt)
                            if let url = URL(string: "https://claude.ai/new") {
                                UIApplication.shared.open(url)
                            }
                            copyConfirm = "🚀 복사됨 → Safari에서 붙여넣기"
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.forward.app.fill")
                                Text("claude.ai 열기")
                            }
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    if let msg = copyConfirm {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(theme.primary)
                            .transition(.opacity)
                    }

                    // Step 3: Paste result
                    stepHeader(n: 3, title: "claude.ai 결과를 여기에 붙여넣기", theme: theme)
                    ZStack(alignment: .topLeading) {
                        if result.isEmpty {
                            Text("claude.ai에서 받은 응답을 길게 눌러 붙여넣기 하세요")
                                .foregroundStyle(theme.textSecondary.opacity(0.5))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $result)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 200)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.textSecondary.opacity(0.15), lineWidth: 1)
                    )

                    if !result.isEmpty {
                        HStack(spacing: 8) {
                            Button {
                                copyToClipboard(result)
                                copyConfirm = "📋 결과 복사됨"
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                    Text("결과 복사")
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(theme.cardBackground)
                                .foregroundStyle(theme.textPrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            Button {
                                Haptic.success()
                                onInsert(result.trimmingCharacters(in: .whitespacesAndNewlines))
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.pencil")
                                    Text("본문에 삽입")
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(theme.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(theme.background)
            .navigationTitle("✨ AI 어시스트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func stepHeader(n: Int, title: String, theme: AppTheme) -> some View {
        HStack(spacing: 8) {
            Text("\(n)")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(theme.primary)
                .clipShape(Circle())
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(theme.textSecondary)
                .textCase(nil)
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        Haptic.success()
    }
}
