import SwiftUI

struct DashboardView: View {
    @Environment(ThemeManager.self) private var themeManager

    private var sponsorships: [SponsorshipDTO] { DataManager.shared.sponsorships }
    private var settlements: [SettlementDTO] { DataManager.shared.settlements }
    private var reelsNotes: [ReelsNoteDTO] { DataManager.shared.reelsNotes }
    private var generalNotes: [GeneralNoteDTO] { DataManager.shared.generalNotes }

    private var activeSponsors: [SponsorshipDTO] {
        sponsorships.filter { !$0.isExpired }
    }

    private var expiringSoon: [SponsorshipDTO] {
        sponsorships.filter { $0.isExpiringSoon }
    }

    private var totalEarnings: Double {
        settlements.filter(\.isPaid).reduce(0) { $0 + $1.netAmount }
    }

    private var pendingSettlements: Int {
        settlements.filter { !$0.isPaid }.count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 6..<12: return "좋은 아침이에요"
        case 12..<18: return "활기찬 오후에요"
        case 18..<22: return "수고한 하루에요"
        default: return "늦은 밤이에요"
        }
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection(theme: theme)

                    // Quick stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatCard(
                            title: "진행중 협찬",
                            value: "\(activeSponsors.count)",
                            icon: "gift.fill"
                        )
                        StatCard(
                            title: "총 수익",
                            value: totalEarnings.krwFormatted,
                            icon: "wonsign.circle.fill"
                        )
                        StatCard(
                            title: "대기중 정산",
                            value: "\(pendingSettlements)",
                            icon: "clock.fill"
                        )
                        StatCard(
                            title: "전체 노트",
                            value: "\(reelsNotes.count + generalNotes.count)",
                            icon: "note.text"
                        )
                    }
                    .padding(.horizontal)

                    // Expiring soon
                    if !expiringSoon.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label {
                                Text("마감 임박")
                                    .font(.headline)
                                    .foregroundStyle(theme.textPrimary)
                            } icon: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                            .padding(.horizontal)

                            ForEach(expiringSoon) { sponsor in
                                ThemedCard {
                                    HStack {
                                        Circle()
                                            .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 36, height: 36)
                                            .overlay {
                                                Text(String(sponsor.brandName.prefix(1)))
                                                    .font(.subheadline.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sponsor.brandName)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(theme.textPrimary)
                                            Text(sponsor.productName)
                                                .font(.caption)
                                                .foregroundStyle(theme.textSecondary)
                                        }
                                        Spacer()
                                        Text("D-\(sponsor.daysRemaining)")
                                            .font(.title3.bold())
                                            .foregroundStyle(.orange)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Recent reels notes
                    if !reelsNotes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("최근 릴스 노트")
                                .font(.headline)
                                .foregroundStyle(theme.textPrimary)
                                .padding(.horizontal)

                            ForEach(reelsNotes.prefix(3)) { note in
                                ThemedCard {
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(statusColor(note.reelsNoteStatus).opacity(0.8))
                                            .frame(width: 4)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(note.title.isEmpty ? "제목 없음" : note.title)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(theme.textPrimary)
                                            Text(note.plainContent.prefix(50))
                                                .font(.caption)
                                                .foregroundStyle(theme.textSecondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        StatusBadge(status: note.reelsNoteStatus)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Empty state
                    if sponsorships.isEmpty && reelsNotes.isEmpty {
                        emptyState(theme: theme)
                    }
                }
                .padding(.bottom, 20)
            }
            .background(theme.background)
            .refreshable {
                await DataManager.shared.fetchAll()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(theme.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func headerSection(theme: AppTheme) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: theme.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay {
                VStack(spacing: 6) {
                    Text(greeting)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Creator Note")
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundStyle(.white)
                    if activeSponsors.count > 0 {
                        Text("진행중인 협찬 \(activeSponsors.count)건")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.2), in: Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func emptyState(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(theme.primary.opacity(0.5))
            Text("시작해볼까요?")
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)
            Text("협찬 정보를 추가하거나\n릴스 노트를 작성해보세요")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private func statusColor(_ status: ReelsNoteStatus) -> Color {
        switch status {
        case .drafting: return .orange
        case .readyToUpload: return .blue
        case .uploaded: return .green
        }
    }
}
