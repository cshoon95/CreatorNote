import SwiftUI

struct SponsorshipListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var filterStatus: SponsorshipStatus?

    private var sponsorships: [SponsorshipDTO] { DataManager.shared.sponsorships }

    private var filtered: [SponsorshipDTO] {
        var result = sponsorships
        if let filterStatus { result = result.filter { $0.sponsorshipStatus == filterStatus } }
        if !searchText.isEmpty {
            result = result.filter {
                $0.brandName.localizedCaseInsensitiveContains(searchText) ||
                $0.productName.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.createdAt > rhs.createdAt
        }
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(theme.textSecondary)
                            TextField("브랜드 검색", text: $searchText)
                                .foregroundStyle(theme.textPrimary)
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(theme.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(theme.surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChipView(label: "전체", count: sponsorships.count, isSelected: filterStatus == nil, theme: theme) { filterStatus = nil }
                                ForEach(SponsorshipStatus.allCases, id: \.self) { s in
                                    let cnt = sponsorships.filter { $0.sponsorshipStatus == s }.count
                                    FilterChipView(label: s.displayName, count: cnt, isSelected: filterStatus == s, theme: theme) { filterStatus = s }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 16)

                        if filtered.isEmpty {
                            emptyState(theme: theme)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { item in
                                    NavigationLink(destination: SponsorshipDetailView(sponsorshipId: item.id)) {
                                        sponsorshipCard(item, theme: theme)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            Task { await DataManager.shared.toggleSponsorshipPin(item) }
                                        } label: {
                                            Label(item.isPinned ? "고정 해제" : "고정", systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill")
                                        }
                                        .tint(.orange)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .refreshable { await DataManager.shared.fetchSponsorships() }

                Button { showingAddSheet = true } label: {
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 56, height: 56)
                        .overlay {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
                .buttonStyle(.plain)
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddSheet) { SponsorshipFormView() }
        }
    }

    private func sponsorshipCard(_ item: SponsorshipDTO, theme: AppTheme) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    if item.isPinned {
                        HStack(spacing: 4) {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.orange)
                            Text("고정됨")
                                .font(.caption2.bold())
                                .foregroundStyle(.orange)
                        }
                    }
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

                VStack(alignment: .trailing, spacing: 6) {
                    SponsorshipStatusBadge(status: item.sponsorshipStatus)
                    Text(item.isExpired ? "만료됨" : "D-\(item.daysRemaining)")
                        .font(.caption2.bold())
                        .foregroundStyle(item.isExpired ? .red : (item.isExpiringSoon ? .orange : theme.primary))
                }
            }

            if item.amount > 0 {
                Divider()
                    .padding(.top, 12)
                    .padding(.horizontal, -16)
                HStack {
                    Text("협찬 금액")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                    Spacer()
                    Text(item.amount.krwFormatted)
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.primary)
                }
                .padding(.top, 10)
            }

            if let createdBy = item.createdBy {
                HStack(spacing: 8) {
                    MemberChip(userId: createdBy)
                    Spacer()
                }
                .padding(.top, 6)
            }
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(theme.divider, lineWidth: 1))
    }

    private func emptyState(theme: AppTheme) -> some View {
        EmptyStateView(icon: "gift.circle.fill", title: "협찬 정보가 없어요", subtitle: "아래 버튼으로 첫 협찬을 추가해보세요", color: theme.primary)
    }
}
