import SwiftUI

enum NoteTemplate: CaseIterable {
    case blank
    case review
    case vlog
    case recipe
    case unboxing
    case ad

    var title: String {
        switch self {
        case .blank: return "빈 노트"
        case .review: return "리뷰"
        case .vlog: return "브이로그"
        case .recipe: return "레시피"
        case .unboxing: return "언박싱"
        case .ad: return "광고/PPL"
        }
    }

    var icon: String {
        switch self {
        case .blank: return "doc"
        case .review: return "star.fill"
        case .vlog: return "video.fill"
        case .recipe: return "fork.knife"
        case .unboxing: return "shippingbox.fill"
        case .ad: return "megaphone.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .blank: return .gray
        case .review: return .orange
        case .vlog: return .pink
        case .recipe: return .green
        case .unboxing: return .brown
        case .ad: return .purple
        }
    }

    var content: String {
        switch self {
        case .blank:
            return ""
        case .review:
            return "인트로:\n\n제품 소개:\n\n장점:\n\n단점:\n\n총평:\n\n#리뷰"
        case .vlog:
            return "오프닝:\n\n본문:\n\n클로징:\n\nBGM:\n\n#브이로그"
        case .recipe:
            return "재료:\n\n조리 과정:\n1.\n2.\n3.\n\n플레이팅 팁:\n\n#레시피"
        case .unboxing:
            return "브랜드:\n\n제품명:\n\n첫인상:\n\n구성품:\n\n한줄평:\n\n#언박싱"
        case .ad:
            return "광고주:\n\n제품/서비스:\n\n핵심 메시지:\n\n스크립트:\n\nCTA:\n\n#광고 #협찬"
        }
    }

    var titlePlaceholder: String {
        switch self {
        case .blank: return ""
        case .review: return "리뷰 제목"
        case .vlog: return "브이로그 제목"
        case .recipe: return "레시피 제목"
        case .unboxing: return "언박싱 제목"
        case .ad: return "광고/PPL 제목"
        }
    }
}

struct NoteTemplateSheet: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    let onSelect: (String, String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        let theme = themeManager.theme
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.textSecondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("템플릿 선택")
                        .font(.title2.bold())
                        .foregroundStyle(theme.textPrimary)
                    Text("원하는 형식으로 빠르게 시작하세요")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                Button {
                    Haptic.selection()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(theme.textSecondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(NoteTemplate.allCases, id: \.self) { template in
                        templateCard(template: template, theme: theme)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(theme.background)
    }

    private func templateCard(template: NoteTemplate, theme: AppTheme) -> some View {
        Button {
            Haptic.selection()
            onSelect(template.content, template.titlePlaceholder)
            dismiss()
        } label: {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    template.iconColor.opacity(0.8),
                                    template.iconColor.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: template.iconColor.opacity(0.25), radius: 8, y: 4)

                    Image(systemName: template.icon)
                        .font(.title2)
                        .foregroundStyle(.white)
                }

                Text(template.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                    .lineLimit(1)

                if template != .blank {
                    Text("양식 포함")
                        .font(.caption2)
                        .foregroundStyle(template.iconColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(template.iconColor.opacity(0.12))
                        .clipShape(Capsule())
                } else {
                    Text("자유 형식")
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.surfaceBackground)
                        .clipShape(Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: theme.primary.opacity(0.07), radius: 8, x: 0, y: 3)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(theme.primary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
