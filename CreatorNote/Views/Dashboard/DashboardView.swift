import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query private var sponsorships: [Sponsorship]
    @Query private var settlements: [Settlement]
    @Query private var reelsNotes: [ReelsNote]

    private var activeSponsors: [Sponsorship] {
        sponsorships.filter { !$0.isExpired }
    }

    private var expiringSoon: [Sponsorship] {
        sponsorships.filter { $0.isExpiringSoon }
    }

    private var totalEarnings: Double {
        settlements.filter(\.isPaid).reduce(0) { $0 + $1.netAmount }
    }

    private var pendingSettlements: Int {
        settlements.filter { !$0.isPaid }.count
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header gradient
                    headerSection(theme: theme)

                    // Stats grid
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
                            title: "릴스 노트",
                            value: "\(reelsNotes.count)",
                            icon: "note.text"
                        )
                    }
                    .padding(.horizontal)

                    // Expiring soon
                    if !expiringSoon.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("마감 임박")
                                    .font(.headline)
                                    .foregroundStyle(theme.textPrimary)
                            }
                            .padding(.horizontal)

                            ForEach(expiringSoon) { sponsor in
                                ThemedCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
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
                                    HStack {
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
                                        StatusBadge(status: note.status)
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
            .navigationTitle("대시보드")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(theme.primary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func headerSection(theme: AppTheme) -> some View {
        VStack(spacing: 8) {
            LinearGradient(
                colors: theme.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                VStack(spacing: 4) {
                    Text("Creator Note")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("오늘도 멋진 콘텐츠를 만들어보세요 ✨")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
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

}
