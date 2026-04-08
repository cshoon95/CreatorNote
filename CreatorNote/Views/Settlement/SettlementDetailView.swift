import SwiftUI

struct SettlementDetailView: View {
    @Environment(ThemeManager.self) private var themeManager
    let settlement: SettlementDTO
    @State private var isEditing = false
    @State private var isPaidLocal: Bool = false

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                ThemedCard {
                    VStack(spacing: 16) {
                        HStack {
                            Text(settlement.brandName)
                                .font(.title3.bold())
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isPaidLocal ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text(isPaidLocal ? "지급 완료" : "대기중")
                                    .font(.caption.bold())
                                    .foregroundStyle(isPaidLocal ? .green : .orange)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background((isPaidLocal ? Color.green : Color.orange).opacity(0.1))
                            .clipShape(Capsule())
                        }

                        Divider()

                        detailRow("총 금액", value: settlement.amount.krwFormatted, theme: theme)
                        detailRow("수수료", value: settlement.fee.krwFormatted, theme: theme)
                        detailRow("세금", value: settlement.tax.krwFormatted, theme: theme)

                        Divider()

                        HStack {
                            Text("실수령액")
                                .font(.headline)
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            Text(settlement.netAmount.krwFormatted)
                                .font(.title2.bold())
                                .foregroundStyle(theme.primary)
                        }

                        if let date = settlement.settlementDate {
                            detailRow("정산일", value: date.formatted(.dateTime.year().month().day()), theme: theme)
                        }

                        // Toggle payment
                        Toggle(isOn: $isPaidLocal) {
                            Text("지급 완료")
                                .foregroundStyle(theme.textPrimary)
                        }
                        .tint(theme.primary)
                        .onChange(of: isPaidLocal) { _, newValue in
                            var updated = settlement
                            updated.isPaid = newValue
                            Task { await DataManager.shared.updateSettlement(updated) }
                        }
                    }
                }
                .padding(.horizontal)

                if !settlement.memo.isEmpty {
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("메모")
                                .font(.headline)
                                .foregroundStyle(theme.textPrimary)
                            Text(settlement.memo)
                                .foregroundStyle(theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(theme.background)
        .navigationTitle("정산 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("편집") { isEditing = true }
                    .foregroundStyle(theme.primary)
            }
        }
        .sheet(isPresented: $isEditing) {
            SettlementFormView(editingSettlement: settlement)
        }
        .onAppear {
            isPaidLocal = settlement.isPaid
        }
    }

    @ViewBuilder
    private func detailRow(_ title: String, value: String, theme: AppTheme) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(theme.textPrimary)
        }
    }

}
