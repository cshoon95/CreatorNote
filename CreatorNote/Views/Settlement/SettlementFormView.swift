import SwiftUI

struct SettlementFormView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    var editingSettlement: SettlementDTO?

    @State private var brandName = ""
    @State private var amountText = ""
    @State private var feeText = ""
    @State private var taxText = ""
    @State private var settlementDate = Date()
    @State private var hasSettlementDate = false
    @State private var isPaid = false
    @State private var memo = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    @FocusState private var focusedField: Field?

    enum Field { case brandName, amount, fee, tax, memo }

    private var parsedAmount: Double { Double(amountText.filter { $0.isNumber }) ?? 0 }
    private var parsedFee: Double { Double(feeText.filter { $0.isNumber }) ?? 0 }
    private var parsedTax: Double { Double(taxText.filter { $0.isNumber }) ?? 0 }

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        return f
    }()

    private func formatCurrency(_ text: String) -> String {
        let digits = text.filter { $0.isNumber }
        guard let number = Int(digits), number > 0 else { return "" }
        let formatted = Self.numberFormatter.string(from: NSNumber(value: number)) ?? digits
        return formatted + "원"
    }
    private var netAmount: Double { parsedAmount - parsedFee - parsedTax }

    private var canSave: Bool {
        !brandName.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    sectionCard(title: "기본 정보", theme: theme) {
                        rowField(theme: theme) {
                            TextField("브랜드명 *", text: $brandName)
                                .focused($focusedField, equals: .brandName)
                                .foregroundStyle(theme.textPrimary)
                        }
                    }

                    sectionCard(title: "금액 정보", theme: theme) {
                        VStack(spacing: 0) {
                            rowField(theme: theme) {
                                HStack(spacing: 8) {
                                    Text("총 금액")
                                        .font(.subheadline)
                                        .foregroundStyle(theme.textSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    TextField("0원", text: $amountText)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .amount)
                                        .foregroundStyle(theme.textPrimary)
                                        .onChange(of: amountText) { _, new in
                                            let formatted = formatCurrency(new)
                                            if formatted != new { amountText = formatted }
                                        }
                                }
                            }
                            Divider()
                                .background(theme.textSecondary.opacity(0.2))
                                .padding(.horizontal, 16)
                            rowField(theme: theme) {
                                HStack(spacing: 8) {
                                    Text("수수료")
                                        .font(.subheadline)
                                        .foregroundStyle(theme.textSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    TextField("0원", text: $feeText)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .fee)
                                        .foregroundStyle(theme.textPrimary)
                                        .onChange(of: feeText) { _, new in
                                            let formatted = formatCurrency(new)
                                            if formatted != new { feeText = formatted }
                                        }
                                }
                            }
                            Divider()
                                .background(theme.textSecondary.opacity(0.2))
                                .padding(.horizontal, 16)
                            rowField(theme: theme) {
                                HStack(spacing: 8) {
                                    Text("세금")
                                        .font(.subheadline)
                                        .foregroundStyle(theme.textSecondary)
                                        .frame(width: 60, alignment: .leading)
                                    TextField("0원", text: $taxText)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .tax)
                                        .foregroundStyle(theme.textPrimary)
                                        .onChange(of: taxText) { _, new in
                                            let formatted = formatCurrency(new)
                                            if formatted != new { taxText = formatted }
                                        }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("실수령액")
                            .font(.caption.bold())
                            .foregroundStyle(theme.textSecondary)
                            .padding(.leading, 4)
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("실수령액")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.textSecondary)
                                Text(netAmount.krwFormatted)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        netAmount >= 0 ? theme.primary : Color.red
                                    )
                                    .contentTransition(.numericText())
                                    .animation(.spring(duration: 0.3), value: netAmount)
                            }
                            Spacer()
                            Image(systemName: "wonsign.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(theme.primary.opacity(0.25))
                        }
                        .padding(20)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                        )
                    }

                    sectionCard(title: "정산 상태", theme: theme) {
                        VStack(spacing: 0) {
                            rowField(theme: theme) {
                                Toggle(isOn: $hasSettlementDate) {
                                    Text("정산일 설정")
                                        .foregroundStyle(theme.textPrimary)
                                }
                                .tint(theme.primary)
                                .onChange(of: hasSettlementDate) { _, _ in Haptic.selection() }
                            }
                            if hasSettlementDate {
                                Divider()
                                    .background(theme.textSecondary.opacity(0.2))
                                    .padding(.horizontal, 16)
                                rowField(theme: theme) {
                                    DatePicker("정산일", selection: $settlementDate, displayedComponents: .date)
                                        .foregroundStyle(theme.textPrimary)
                                        .tint(theme.primary)
                                }
                            }
                            Divider()
                                .background(theme.textSecondary.opacity(0.2))
                                .padding(.horizontal, 16)
                            rowField(theme: theme) {
                                Toggle(isOn: $isPaid) {
                                    Text("지급 완료")
                                        .foregroundStyle(theme.textPrimary)
                                }
                                .tint(theme.primary)
                                .onChange(of: isPaid) { _, _ in Haptic.selection() }
                            }
                        }
                    }

                    sectionCard(title: "메모", theme: theme) {
                        TextEditor(text: $memo)
                            .focused($focusedField, equals: .memo)
                            .foregroundStyle(theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .scrollDisabled(true)
                            .frame(minHeight: 100)
                            .padding(16)
                    }

                    Spacer().frame(height: 20)
                }
                .padding()
            }
            .background(theme.background)
            .navigationTitle(editingSettlement == nil ? "정산 추가" : "정산 편집")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isLoading {
                            ProgressView().scaleEffect(0.85)
                        } else {
                            Text("저장")
                                .fontWeight(.semibold)
                                .foregroundStyle(canSave ? theme.primary : theme.textSecondary.opacity(0.5))
                        }
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear { loadIfEditing() }
            .onChange(of: showError) {
                guard showError, let msg = errorMessage else { return }
                showError = false
                AlertManager.shared.show(title: "오류", message: msg)
            }
        }
    }

    private func sectionCard<Content: View>(title: String, theme: AppTheme, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(theme.textSecondary)
                .padding(.leading, 4)
            content()
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func rowField<Content: View>(theme: AppTheme, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

    private func loadIfEditing() {
        guard let s = editingSettlement else { return }
        brandName = s.brandName
        if s.amount > 0 { amountText = formatCurrency(String(Int(s.amount))) }
        if s.fee > 0 { feeText = formatCurrency(String(Int(s.fee))) }
        if s.tax > 0 { taxText = formatCurrency(String(Int(s.tax))) }
        hasSettlementDate = s.settlementDate != nil
        settlementDate = s.settlementDate ?? Date()
        isPaid = s.isPaid
        memo = s.memo
    }

    private func save() async {
        isLoading = true
        defer { isLoading = false }
        DataManager.shared.errorMessage = nil
        let trimmedBrand = brandName.trimmingCharacters(in: .whitespaces)
        if var updated = editingSettlement {
            updated.brandName = trimmedBrand
            updated.amount = parsedAmount
            updated.fee = parsedFee
            updated.tax = parsedTax
            updated.settlementDate = hasSettlementDate ? settlementDate : nil
            updated.isPaid = isPaid
            updated.memo = memo
            await DataManager.shared.updateSettlement(updated)
        } else {
            await DataManager.shared.createSettlement(
                brandName: trimmedBrand,
                amount: parsedAmount,
                fee: parsedFee,
                tax: parsedTax,
                settlementDate: hasSettlementDate ? settlementDate : nil,
                isPaid: isPaid,
                memo: memo
            )
        }
        if let msg = DataManager.shared.errorMessage {
            errorMessage = msg
            showError = true
        } else {
            dismiss()
        }
    }
}
