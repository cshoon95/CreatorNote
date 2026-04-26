import SwiftUI

struct SettlementDetailView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    let settlement: SettlementDTO

    @State private var isPaidLocal: Bool = false
    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 16) {
                heroCard(theme: theme)
                    .padding(.horizontal)

                amountCard(theme: theme)
                    .padding(.horizontal)

                if let date = settlement.settlementDate {
                    dateCard(date: date, theme: theme)
                        .padding(.horizontal)
                }

                if !settlement.memo.isEmpty {
                    memoCard(theme: theme)
                        .padding(.horizontal)
                }

                paymentToggleButton(theme: theme)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
            .padding(.vertical, 16)
        }
        .background(theme.background)
        .navigationTitle("정산 상세")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(theme.colorScheme)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("편집") { isEditing = true }
                    Divider()
                    Button("삭제", role: .destructive) {
                        AlertManager.shared.confirm(
                            title: "정산을 삭제하시겠습니까?",
                            message: "삭제된 정산은 복구할 수 없습니다"
                        ) {
                            Task {
                                await DataManager.shared.deleteSettlement(id: settlement.id)
                                dismiss()
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(theme.primary)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            SettlementFormView(editingSettlement: settlement)
        }
        .onAppear {
            isPaidLocal = settlement.isPaid
        }
    }

    private func heroCard(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            theme.primary
                        )
                        .frame(width: 60, height: 60)
                    Text(String(settlement.brandName.prefix(1)))
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(settlement.brandName)
                        .font(.title3.bold())
                        .foregroundStyle(theme.textPrimary)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isPaidLocal ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)
                        Text(isPaidLocal ? "지급 완료" : "대기중")
                            .font(.caption.bold())
                            .foregroundStyle(isPaidLocal ? .green : .orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((isPaidLocal ? Color.green : Color.orange).opacity(0.12))
                    .clipShape(Capsule())
                }

                Spacer()
            }
        }
        .padding(20)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
    }

    private func amountCard(theme: AppTheme) -> some View {
        VStack(spacing: 0) {
            HStack {
                Label("금액 내역", systemImage: "wonsign.circle")
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textSecondary)
                Spacer()
            }
            .padding(.bottom, 14)

            amountRow(label: "총 금액", value: settlement.amount.krwFormatted, theme: theme, isHighlight: false)

            Rectangle()
                .fill(theme.textSecondary.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 10)

            amountRow(label: "수수료", value: "- \(settlement.fee.krwFormatted)", theme: theme, isHighlight: false)
                .padding(.bottom, 8)

            amountRow(label: "세금", value: "- \(settlement.tax.krwFormatted)", theme: theme, isHighlight: false)

            Rectangle()
                .fill(theme.textSecondary.opacity(0.1))
                .frame(height: 1)
                .padding(.vertical, 14)

            HStack {
                Text("실수령액")
                    .font(.headline.bold())
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(settlement.netAmount.krwFormatted)
                    .font(.title2.bold())
                    .foregroundStyle(theme.primary)
            }
        }
        .padding(20)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.05), radius: 12, y: 4)
    }

    private func amountRow(label: String, value: String, theme: AppTheme, isHighlight: Bool) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(isHighlight ? theme.primary : theme.textPrimary)
        }
    }

    private func dateCard(date: Date, theme: AppTheme) -> some View {
        HStack {
            Label("정산일", systemImage: "calendar")
                .font(.subheadline)
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(date.formatted(.dateTime.year().month().day()))
                .font(.subheadline.bold())
                .foregroundStyle(theme.textPrimary)
        }
        .padding(20)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 3)
    }

    private func memoCard(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("메모", systemImage: "note.text")
                .font(.subheadline.bold())
                .foregroundStyle(theme.textSecondary)
            Text(settlement.memo)
                .font(.body)
                .foregroundStyle(theme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 3)
    }

    private func paymentToggleButton(theme: AppTheme) -> some View {
        Button {
            Haptic.success()
            withAnimation(.spring(duration: 0.3)) {
                isPaidLocal.toggle()
                var updated = settlement
                updated.isPaid = isPaidLocal
                Task { await DataManager.shared.updateSettlement(updated) }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isPaidLocal ? "arrow.uturn.left.circle.fill" : "checkmark.circle.fill")
                Text(isPaidLocal ? "대기 중으로 변경" : "지급 완료 처리")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(isPaidLocal ? .orange : theme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }
}
