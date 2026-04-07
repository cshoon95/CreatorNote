import SwiftUI
import SwiftData

struct SponsorshipFormView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingSponsorship: Sponsorship?

    @State private var brandName = ""
    @State private var productName = ""
    @State private var details = ""
    @State private var amount: Double = 0
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 30)

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            Form {
                Section {
                    TextField("브랜드명", text: $brandName)
                    TextField("제품명", text: $productName)
                } header: {
                    Text("기본 정보")
                }

                Section {
                    HStack {
                        Text("₩")
                        TextField("금액", value: $amount, format: .number)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("금액")
                }

                Section {
                    DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                    DatePicker("종료일", selection: $endDate, displayedComponents: .date)
                } header: {
                    Text("기간")
                }

                Section {
                    TextEditor(text: $details)
                        .frame(minHeight: 100)
                } header: {
                    Text("세부 내용")
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle(editingSponsorship == nil ? "협찬 추가" : "협찬 편집")
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
        guard let s = editingSponsorship else { return }
        brandName = s.brandName
        productName = s.productName
        details = s.details
        amount = s.amount
        startDate = s.startDate
        endDate = s.endDate
    }

    private func save() {
        if let s = editingSponsorship {
            s.brandName = brandName
            s.productName = productName
            s.details = details
            s.amount = amount
            s.startDate = startDate
            s.endDate = endDate
            s.updatedAt = .now
        } else {
            let s = Sponsorship(
                brandName: brandName,
                productName: productName,
                details: details,
                amount: amount,
                startDate: startDate,
                endDate: endDate
            )
            modelContext.insert(s)
        }
        dismiss()
    }
}
