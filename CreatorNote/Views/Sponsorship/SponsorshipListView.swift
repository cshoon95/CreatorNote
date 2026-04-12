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
        return result
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
                        .padding(14)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                filterChip("전체", count: sponsorships.count, isSelected: filterStatus == nil, theme: theme) { filterStatus = nil }
                                ForEach(SponsorshipStatus.allCases, id: \.self) { s in
                                    let cnt = sponsorships.filter { $0.sponsorshipStatus == s }.count
                                    filterChip(s.displayName, count: cnt, isSelected: filterStatus == s, theme: theme) { filterStatus = s }
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
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .refreshable { await DataManager.shared.fetchSponsorships() }

                Button { showingAddSheet = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.body.bold())
                        Text("협찬 추가")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(LinearGradient(colors: theme.gradient, startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
                    .shadow(color: theme.primary.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddSheet) { SponsorshipFormView() }
        }
    }

    private func sponsorshipCard(_ item: SponsorshipDTO, theme: AppTheme) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                GradientAvatarView(text: item.brandName, gradient: theme.gradient)

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
        }
        .padding(18)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private func filterChip(_ label: String, count: Int, isSelected: Bool, theme: AppTheme, action: @escaping () -> Void) -> some View {
        Button {
            Haptic.selection()
            withAnimation(.spring(duration: 0.25)) { action() }
        } label: {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption.bold())
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isSelected ? .white.opacity(0.3) : theme.primary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? theme.primary : theme.cardBackground)
            .foregroundStyle(isSelected ? .white : theme.textSecondary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? theme.primary.opacity(0.3) : .clear, radius: 6, y: 2)
        }
    }

    private func emptyState(theme: AppTheme) -> some View {
        EmptyStateView(icon: "gift.circle.fill", title: "협찬 정보가 없어요", subtitle: "아래 버튼으로 첫 협찬을 추가해보세요", color: theme.primary)
    }
}
