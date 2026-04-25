import SwiftUI

struct ThemedCard<Content: View>: View {
    @Environment(ThemeManager.self) private var themeManager
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        let theme = themeManager.theme
        content()
            .padding(16)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(theme.divider, lineWidth: 1)
            )
            .shadow(color: theme.primary.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct StatCard: View {
    @Environment(ThemeManager.self) private var themeManager
    let title: String
    let value: String
    let icon: String
    var trend: String? = nil

    var body: some View {
        let theme = themeManager.theme
        ThemedCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(theme.primary)
                    Spacer()
                    if let trend {
                        Text(trend)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.accent)
                    }
                }
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }
}

struct StatusBadge: View {
    @Environment(ThemeManager.self) private var themeManager
    let status: ReelsNoteStatus

    var body: some View {
        let (bgColor, fgColor): (Color, Color) = {
            switch status {
            case .drafting: return (Color(hex: "FEF3C7"), Color(hex: "D97706"))
            case .readyToUpload: return (Color(hex: "DBEAFE"), Color(hex: "2563EB"))
            case .uploaded: return (Color(hex: "D1FAE5"), Color(hex: "059669"))
            }
        }()
        Text(status.displayName)
            .font(.caption2.bold())
            .foregroundStyle(fgColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bgColor)
            .clipShape(Capsule())
    }
}

struct MemberChip: View {
    @Environment(ThemeManager.self) private var themeManager
    let userId: UUID?

    private var name: String {
        guard let userId else { return "알 수 없음" }
        if userId == AuthManager.shared.currentUser?.id { return "나" }
        return WorkspaceManager.shared.members.first { $0.id == userId }?.displayName ?? "멤버"
    }

    private var initial: String {
        String(name.prefix(1))
    }

    var body: some View {
        let theme = themeManager.theme
        HStack(spacing: 4) {
            Circle()
                .fill(ProfileColor.color(for: userId))
                .frame(width: 16, height: 16)
                .overlay {
                    Text(initial)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                }
            Text(name)
                .font(.caption2)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(theme.primary.opacity(0.06))
        .clipShape(Capsule())
    }
}

enum ProfileColor {
    static let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal, .indigo, .mint]

    static func color(for userId: UUID?) -> Color {
        guard let userId else { return .gray }
        let hash = abs(userId.hashValue)
        return colors[hash % colors.count]
    }
}

struct FilterChipView: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let theme: AppTheme
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { action() }
        } label: {
            HStack(spacing: 3) {
                Text(label)
                    .font(.caption.bold())
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                }
            }
            .foregroundStyle(isSelected ? .white : theme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? theme.primary : theme.surfaceBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension ReelsNoteStatus {
    var color: Color {
        switch self {
        case .drafting: return .orange
        case .readyToUpload: return .blue
        case .uploaded: return .green
        }
    }
}

struct SponsorshipStatusBadge: View {
    let status: SponsorshipStatus

    private var colors: (Color, Color) {
        switch status {
        case .preSubmit: return (Color(hex: "F3F4F6"), Color(hex: "6B7280"))
        case .underReview: return (Color(hex: "FEF3C7"), Color(hex: "D97706"))
        case .submitted: return (Color(hex: "DBEAFE"), Color(hex: "2563EB"))
        case .pendingSettlement: return (Color(hex: "FEE2E2"), Color(hex: "DC2626"))
        case .completed: return (Color(hex: "D1FAE5"), Color(hex: "059669"))
        }
    }

    var body: some View {
        let (bg, fg) = colors
        Text(status.displayName)
            .font(.caption2.bold())
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(Capsule())
    }
}
