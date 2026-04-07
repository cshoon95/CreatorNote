import SwiftUI
import SwiftData

struct SettlementListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Settlement.createdAt, order: .reverse) private var settlements: [Settlement]
    @State private var showingAddSheet = false
    @State private var filterPaid: Bool? = nil

    private var filtered: [Settlement] {
        guard let filterPaid else { return settlements }
        return settlements.filter { $0.isPaid == filterPaid }
    }

    private var totalNet: Double {
        settlements.reduce(0) { $0 + $1.netAmount }
    }

    private var paidTotal: Double {
        settlements.filter(\.isPaid).reduce(0) { $0 + $1.netAmount }
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            VStack(spacing: 0) {
                // Summary header
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        summaryPill(title: "총 정산", value: totalNet.krwFormatted, theme: theme)
                        summaryPill(title: "지급 완료", value: paidTotal.krwFormatted, theme: theme)
                    }
                    .padding(.horizontal)

                    // Filter
                    Picker("필터", selection: $filterPaid) {
                        Text("전체").tag(Optional<Bool>.none)
                        Text("지급 완료").tag(Optional<Bool>.some(true))
                        Text("대기중").tag(Optional<Bool>.some(false))
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(theme.surfaceBackground)

                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "wonsign.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(theme.primary.opacity(0.5))
                        Text("정산 내역이 없습니다")
                            .foregroundStyle(theme.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filtered) { item in
                            NavigationLink(destination: SettlementDetailView(settlement: item)) {
                                settlementRow(item, theme: theme)
                            }
                            .listRowBackground(theme.cardBackground)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(theme.background)
            .navigationTitle("정산")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                SettlementFormView()
            }
        }
    }

    @ViewBuilder
    private func summaryPill(title: String, value: String, theme: AppTheme) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(theme.textSecondary)
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(theme.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func settlementRow(_ item: Settlement, theme: AppTheme) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.brandName)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                if let date = item.settlementDate {
                    Text(date, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.netAmount.krwFormatted)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                HStack(spacing: 4) {
                    Circle()
                        .fill(item.isPaid ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(item.isPaid ? "지급 완료" : "대기중")
                        .font(.caption)
                        .foregroundStyle(item.isPaid ? .green : .orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filtered[index])
        }
    }

}
