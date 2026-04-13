import SwiftUI

struct ThemedCard<Content: View>: View {
    @Environment(ThemeManager.self) private var themeManager
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    private var isFlat: Bool {
        themeManager.theme.type == .clean || themeManager.theme.type == .pastel
    }

    var body: some View {
        let theme = themeManager.theme
        content()
            .padding(16)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: isFlat ? 12 : 16))
            .overlay(
                RoundedRectangle(cornerRadius: isFlat ? 12 : 16)
                    .stroke(theme.divider, lineWidth: isFlat ? 0.5 : 0)
            )
            .shadow(color: isFlat ? .clear : theme.primary.opacity(0.08), radius: 8, x: 0, y: 4)
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
        let color: Color = {
            switch status {
            case .drafting: return .orange
            case .readyToUpload: return .blue
            case .uploaded: return .green
            }
        }()

        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(status.displayName)
                .font(.caption2)
        }
        .foregroundStyle(color)
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
        HStack(spacing: 3) {
            Circle()
                .fill(theme.primary.opacity(0.7))
                .frame(width: 14, height: 14)
                .overlay {
                    Text(initial)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                }
            Text(name)
                .font(.caption2)
                .foregroundStyle(theme.textSecondary)
        }
    }
}

struct SponsorshipStatusBadge: View {
    let status: SponsorshipStatus

    private var color: Color {
        switch status {
        case .preSubmit: return .gray
        case .underReview: return .orange
        case .submitted: return .blue
        case .pendingSettlement: return .purple
        case .completed: return .green
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(status.displayName)
                .font(.caption2)
        }
        .foregroundStyle(color)
    }
}

