import SwiftUI
import SwiftData

struct SponsorshipListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sponsorship.endDate) private var sponsorships: [Sponsorship]
    @State private var showingAddSheet = false
    @State private var searchText = ""

    private var filtered: [Sponsorship] {
        if searchText.isEmpty { return sponsorships }
        return sponsorships.filter {
            $0.brandName.localizedCaseInsensitiveContains(searchText) ||
            $0.productName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            Group {
                if sponsorships.isEmpty {
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
                if item.isExpired {
                    Text("만료됨")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                } else if item.isExpiringSoon {
                    Text("D-\(item.daysRemaining)")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                } else {
                    Text("D-\(item.daysRemaining)")
                        .font(.caption.bold())
                        .foregroundStyle(theme.primary)
                }
                if item.isSettled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }
}
