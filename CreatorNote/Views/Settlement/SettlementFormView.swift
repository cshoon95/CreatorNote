import SwiftUI
import SwiftData

struct SettlementFormView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingSettlement: Settlement?

    @State private var brandName = ""
    @State private var amount: Double = 0
    @State private var fee: Double = 0
    @State private var tax: Double = 0
    @State private var settlementDate = Date()
    @State private var hasSettlementDate = false
    @State private var isPaid = false
    @State private var memo = ""

    private var netAmount: Double {
        amount - fee - tax
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            Form {
                Section {
                    TextField("브랜드명", text: $brandName)
                } header: {
                    Text("기본 정보")
                }

                Section {
                    HStack {
                        Text("총 금액 ₩")
                        TextField("금액", value: $amount, format: .number)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("수수료 ₩")
                        TextField("수수료", value: $fee, format: .number)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("세금 ₩")
                        TextField("세금", value: $tax, format: .number)
                            .keyboardType(.numberPad)
                    }
                    HStack {
                        Text("실수령액")
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatCurrency(netAmount))
                            .fontWeight(.bold)
                            .foregroundStyle(theme.primary)
                    }
                } header: {
                    Text("금액 정보")
                }

                Section {
                    Toggle("정산일 설정", isOn: $hasSettlementDate)
                    if hasSettlementDate {
                        DatePicker("정산일", selection: $settlementDate, displayedComponents: .date)
                    }
                    Toggle("지급 완료", isOn: $isPaid)
                } header: {
                    Text("정산 상태")
                }

                Section {
                    TextEditor(text: $memo)
                        .frame(minHeight: 80)
                } header: {
                    Text("메모")
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle(editingSettlement == nil ? "정산 추가" : "정산 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .disabled(brandName.isEmpty)
                        .foregroundStyle(theme.primary)
                }
            }
            .onAppear { loadIfEditing() }
        }
    }

    private func loadIfEditing() {
        guard let s = editingSettlement else { return }
        brandName = s.brandName
        amount = s.amount
        fee = s.fee
        tax = s.tax
        hasSettlementDate = s.settlementDate != nil
        settlementDate = s.settlementDate ?? Date()
        isPaid = s.isPaid
        memo = s.memo
    }

    private func save() {
        if let s = editingSettlement {
            s.brandName = brandName
            s.amount = amount
            s.fee = fee
            s.tax = tax
            s.netAmount = netAmount
            s.settlementDate = hasSettlementDate ? settlementDate : nil
            s.isPaid = isPaid
            s.memo = memo
        } else {
            let s = Settlement(
                brandName: brandName,
                amount: amount,
                fee: fee,
                tax: tax,
                settlementDate: hasSettlementDate ? settlementDate : nil,
                isPaid: isPaid,
                memo: memo
            )
            modelContext.insert(s)
        }
        dismiss()
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₩0"
    }
}
