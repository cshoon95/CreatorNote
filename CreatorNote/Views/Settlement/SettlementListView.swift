import SwiftUI

struct SettlementListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var showingAddSheet = false
    @State private var filterTab: FilterTab = .all

    enum FilterTab: CaseIterable {
        case all, pending, paid
        var label: String {
            switch self {
            case .all: return "전체"
            case .pending: return "대기중"
            case .paid: return "완료"
            }
        }
    }

    private var settlements: [SettlementDTO] { DataManager.shared.settlements }

    private var filtered: [SettlementDTO] {
        switch filterTab {
        case .all:     return settlements
        case .pending: return settlements.filter { !$0.isPaid }
        case .paid:    return settlements.filter {  $0.isPaid }
        }
    }

    private var totalNet: Double    { settlements.reduce(0) { $0 + $1.netAmount } }
    private var paidTotal: Double   { settlements.filter(\.isPaid).reduce(0) { $0 + $1.netAmount } }
    private var pendingTotal: Double { settlements.filter { !$0.isPaid }.reduce(0) { $0 + $1.netAmount } }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        heroCard(theme: theme)
                            .padding(.horizontal)
                            .padding(.top, 12)
                            .padding(.bottom, 20)

                        filterTabs(theme: theme)
                            .padding(.horizontal)
                            .padding(.bottom, 20)

                        if filtered.isEmpty {
                            emptyState(theme: theme)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { item in
                                    NavigationLink(destination: SettlementDetailView(settlement: item)) {
                                        settlementCard(item, theme: theme)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Task { await DataManager.shared.deleteSettlement(id: item.id) }
                                        } label: {
                                            Label("삭제", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        Spacer().frame(height: 100)
                    }
                }
                .refreshable { await DataManager.shared.fetchSettlements() }

                Button { showingAddSheet = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.body.bold())
                        Text("정산 추가")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: theme.gradient, startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: theme.primary.opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .sheet(isPresented: $showingAddSheet) { SettlementFormView() }
        }
    }

    private func heroCard(theme: AppTheme) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("총 실수령액")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(totalNet.krwFormatted)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 24)

            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 20)

            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("지급 완료")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(paidTotal.krwFormatted)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 1, height: 36)

                VStack(spacing: 4) {
                    Text("대기중")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(pendingTotal.krwFormatted)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 18)
        }
        .background(
            LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: theme.primary.opacity(0.35), radius: 16, y: 6)
    }

    private func filterTabs(theme: AppTheme) -> some View {
        HStack(spacing: 8) {
            ForEach(FilterTab.allCases, id: \.self) { tab in
                Button {
                    Haptic.selection()
                    withAnimation(.spring(duration: 0.25)) { filterTab = tab }
                } label: {
                    Text(tab.label)
                        .font(.subheadline.bold())
                        .foregroundStyle(filterTab == tab ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(
                            filterTab == tab
                                ? AnyShapeStyle(LinearGradient(colors: theme.gradient, startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(theme.cardBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: filterTab == tab ? theme.primary.opacity(0.3) : .clear, radius: 6, y: 2)
                }
            }
        }
    }

    private func settlementCard(_ item: SettlementDTO, theme: AppTheme) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.isPaid ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: item.isPaid ? "checkmark.circle.fill" : "clock.fill")
                    .font(.title3)
                    .foregroundStyle(item.isPaid ? .green : .orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.brandName)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                if let date = item.settlementDate {
                    Text(date, format: .dateTime.year().month().day())
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                } else {
                    Text("날짜 미정")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.netAmount.krwFormatted)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                Text(item.isPaid ? "지급 완료" : "대기중")
                    .font(.caption.bold())
                    .foregroundStyle(item.isPaid ? .green : .orange)
            }
        }
        .padding(18)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private func emptyState(theme: AppTheme) -> some View {
        EmptyStateView(icon: "wonsign.circle.fill", title: "정산 내역이 없어요", subtitle: "아래 버튼으로 첫 정산을 추가해보세요", color: theme.primary)
    }
}
