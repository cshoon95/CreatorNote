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
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: theme.primary.opacity(0.08), radius: 8, x: 0, y: 4)
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
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
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
            Image(systemName: status.icon)
                .font(.caption2)
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

