import SwiftUI
import SwiftData

struct SponsorshipListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sponsorship.endDate) private var sponsorships: [Sponsorship]
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var filterStatus: SponsorshipStatus? = nil

    private var filtered: [Sponsorship] {
        var result = sponsorships
        if let filterStatus {
            result = result.filter { $0.status == filterStatus }
        }
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
            VStack(spacing: 0) {
                if !sponsorships.isEmpty {
                    // Status filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterChip(label: "전체", isSelected: filterStatus == nil, theme: theme) {
                                filterStatus = nil
                            }
                            ForEach(SponsorshipStatus.allCases, id: \.self) { s in
                                filterChip(label: s.rawValue, isSelected: filterStatus == s, theme: theme) {
                                    filterStatus = s
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .background(theme.surfaceBackground)
                }

                if filtered.isEmpty {
                    emptyState(theme: theme)
                } else {
                    List {
                        ForEach(filtered) { item in
                            NavigationLink(destination: SponsorshipDetailView(sponsorship: item)) {
                                sponsorshipRow(item, theme: theme)
                            }
                            .listRowBackground(theme.cardBackground)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                    .background(theme.background)
                    .searchable(text: $searchText, prompt: "브랜드 검색")
                }
            }
            .navigationTitle("협찬 관리")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                SponsorshipFormView()
            }
        }
    }

    @ViewBuilder
    private func sponsorshipRow(_ item: Sponsorship, theme: AppTheme) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(String(item.brandName.prefix(1)))
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.brandName)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                Text(item.productName)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                SponsorshipStatusBadge(status: item.status)
                if item.isExpired {
                    Text("만료됨")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                } else {
                    Text("D-\(item.daysRemaining)")
                        .font(.caption2.bold())
                        .foregroundStyle(item.isExpiringSoon ? .orange : theme.primary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func emptyState(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "gift")
                .font(.system(size: 48))
                .foregroundStyle(theme.primary.opacity(0.5))
            Text("협찬 정보가 없습니다")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)
            Text("+ 버튼을 눌러 협찬을 추가하세요")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }

    @ViewBuilder
    private func filterChip(label: String, isSelected: Bool, theme: AppTheme, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptic.selection()
            withAnimation { action() }
        }) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? theme.primary : theme.cardBackground)
                .foregroundStyle(isSelected ? .white : theme.textSecondary)
                .clipShape(Capsule())
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }
}
