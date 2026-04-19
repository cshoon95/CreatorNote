import SwiftUI

struct DashboardView: View {
    @Environment(ThemeManager.self) private var themeManager

    private var sponsorships: [SponsorshipDTO] { DataManager.shared.sponsorships }
    private var reelsNotes: [ReelsNoteDTO] { DataManager.shared.reelsNotes }
    private var generalNotes: [GeneralNoteDTO] { DataManager.shared.generalNotes }

    private var activeSponsors: [SponsorshipDTO] {
        sponsorships.filter { !$0.isExpired }
    }
    private var expiringSoon: [SponsorshipDTO] {
        sponsorships.filter { $0.isExpiringSoon }
    }
    private var pendingSettlements: [SponsorshipDTO] {
        sponsorships.filter { $0.sponsorshipStatus == .pendingSettlement }
    }
    private var pendingAmount: Double {
        pendingSettlements.reduce(0) { $0 + $1.amount }
    }
    private var totalEarnings: Double {
        sponsorships.filter { $0.sponsorshipStatus == .completed }.reduce(0) { $0 + $1.amount }
    }
    private var todayDeadlines: [SponsorshipDTO] {
        sponsorships.filter { Calendar.current.isDateInToday($0.endDate) }
    }
    private var urgentItems: [SponsorshipDTO] {
        sponsorships.filter { $0.daysRemaining <= 3 && $0.daysRemaining >= 0 && !$0.isExpired }
    }
    private var draftNotes: [ReelsNoteDTO] {
        reelsNotes.filter { $0.reelsNoteStatus == .drafting }
    }
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: .now)
        switch h {
        case 6..<12: return "좋은 아침이에요 ☀️"
        case 12..<18: return "활기찬 오후에요 🌤"
        case 18..<22: return "수고한 하루에요 🌙"
        default: return "늦은 밤이에요 🌛"
        }
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerCard(theme: theme)
                        .padding(.top, 8)

                    HStack(spacing: 12) {
                        miniStatCard(
                            title: "총 수익",
                            icon: "wonsign.circle.fill",
                            iconColor: theme.primary,
                            primary: totalEarnings.krwFormatted,
                            sub: "완료된 협찬",
                            theme: theme
                        )
                        miniStatCard(
                            title: "전체 노트",
                            icon: "note.text",
                            iconColor: theme.accent,
                            primary: "\(reelsNotes.count + generalNotes.count)",
                            sub: "릴스 \(reelsNotes.count) · 메모 \(generalNotes.count)",
                            theme: theme
                        )
                    }
                    .padding(.horizontal)

                    if !todayDeadlines.isEmpty || !urgentItems.isEmpty || !draftNotes.isEmpty {
                        todaySection(theme: theme)
                    }

                    if !pendingSettlements.isEmpty {
                        pendingSection(theme: theme)
                    }

                    if !expiringSoon.isEmpty {
                        expiringSection(theme: theme)
                    }

                    if !reelsNotes.isEmpty {
                        recentNotesSection(theme: theme)
                    }

                    if sponsorships.isEmpty && reelsNotes.isEmpty {
                        emptyState(theme: theme)
                    }
                }
                .padding(.bottom, 8)
            }
            .background(theme.background)
            .refreshable { await DataManager.shared.fetchAll() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: GlobalSearchView()) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.primary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func headerCard(theme: AppTheme) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 14) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 6) {
                    Text("✦ v2.0")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.18))
                        .clipShape(Capsule())
                }

                Text("Influe")
                    .font(.system(.largeTitle, design: .rounded).bold())
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    headerStat(label: "진행중", value: "\(activeSponsors.count)건")
                    headerStatDivider()
                    headerStat(label: "정산 대기", value: "\(pendingSettlements.count)건")
                    headerStatDivider()
                    headerStat(label: "마감 임박", value: "\(expiringSoon.count)건")
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
        .frame(height: 180)
        .padding(.horizontal)
    }

    private func headerStat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
    }

    private func headerStatDivider() -> some View {
        Rectangle()
            .fill(.white.opacity(0.3))
            .frame(width: 1, height: 28)
    }

    private func miniStatCard(title: String, icon: String, iconColor: Color, primary: String, sub: String, theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(iconColor)
                }
                Spacer()
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(theme.textSecondary)
            }
            Text(primary)
                .font(.title3.bold())
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(sub)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: theme.primary.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private func todaySection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("오늘 할 일", systemImage: "checklist")
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal)

            ForEach(todayDeadlines) { item in
                ThemedCard {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.brandName)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textPrimary)
                            Text("오늘 마감!")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                        Spacer()
                        Text("D-Day")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }

            ForEach(urgentItems.filter { urgent in !todayDeadlines.contains(where: { d in d.id == urgent.id }) }) { item in
                ThemedCard {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.brandName)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textPrimary)
                            Text("\(item.daysRemaining)일 후 마감")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        Text("D-\(item.daysRemaining)")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal)
            }

            ForEach(draftNotes.prefix(2)) { note in
                ThemedCard {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(theme.primary.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.primary)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(note.title.isEmpty ? "제목 없음" : note.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textPrimary)
                            Text("작성 중인 노트")
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        Spacer()
                        StatusBadge(status: note.reelsNoteStatus)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func pendingSection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("정산 대기", systemImage: "clock.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(pendingAmount.krwFormatted)
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }
            .padding(.horizontal)

            ForEach(pendingSettlements) { item in
                ThemedCard {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: "clock.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.brandName)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textPrimary)
                            if !item.productName.isEmpty {
                                Text(item.productName)
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                        Spacer()
                        Text(item.amount.krwFormatted)
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func expiringSection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("마감 임박", systemImage: "exclamationmark.triangle.fill")
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal)

            ForEach(expiringSoon) { item in
                ThemedCard {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .overlay {
                                Text(String(item.brandName.prefix(1)))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.brandName)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textPrimary)
                            if !item.productName.isEmpty {
                                Text(item.productName)
                                    .font(.caption)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("D-\(item.daysRemaining)")
                                .font(.title3.bold())
                                .foregroundStyle(.orange)
                            Text("남음")
                                .font(.caption2)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func recentNotesSection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 릴스 노트")
                .font(.headline.weight(.bold))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal)

            ForEach(reelsNotes.prefix(3)) { note in
                ThemedCard {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(note.reelsNoteStatus.color.opacity(0.8))
                            .frame(width: 4, height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(note.title.isEmpty ? "제목 없음" : note.title)
                                .font(.subheadline.bold())
                                .foregroundStyle(theme.textPrimary)
                                .lineLimit(1)
                            Text(note.plainContent.isEmpty ? "내용 없음" : note.plainContent)
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

    private func emptyState(theme: AppTheme) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.08))
                    .frame(width: 96, height: 96)
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(theme.primary.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text("시작해볼까요?")
                    .font(.title3.bold())
                    .foregroundStyle(theme.textPrimary)
                Text("협찬 정보를 추가하거나\n릴스 노트를 작성해보세요")
                    .font(.subheadline)
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 60)
    }

}
