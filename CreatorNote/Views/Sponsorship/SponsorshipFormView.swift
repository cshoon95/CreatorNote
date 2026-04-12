import SwiftUI

struct SponsorshipFormView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    var editingSponsorship: SponsorshipDTO?

    @State private var brandName = ""
    @State private var productName = ""
    @State private var details = ""
    @State private var amountText = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 30)
    @State private var status: SponsorshipStatus = .preSubmit
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    @FocusState private var focusedField: Field?
    enum Field { case brandName, productName, amount, details }

    private var parsedAmount: Double {
        Double(amountText.filter { $0.isNumber }) ?? 0
    }

    private var canSave: Bool {
        !brandName.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 기본 정보
                    sectionCard(title: "기본 정보", theme: theme) {
                        VStack(spacing: 0) {
                            rowField(theme: theme) {
                                TextField("브랜드명 *", text: $brandName)
                                    .focused($focusedField, equals: .brandName)
                                    .foregroundStyle(theme.textPrimary)
                            }
                            Divider()
                                .background(theme.textSecondary.opacity(0.2))
                                .padding(.horizontal, 16)
                            rowField(theme: theme) {
                                TextField("제품명", text: $productName)
                                    .focused($focusedField, equals: .productName)
                                    .foregroundStyle(theme.textPrimary)
                            }
                        }
                    }

                    // 금액
                    sectionCard(title: "금액", theme: theme) {
                        rowField(theme: theme) {
                            HStack(spacing: 6) {
                                TextField("0", text: $amountText)
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .amount)
                                    .foregroundStyle(theme.textPrimary)
                                    .onChange(of: amountText) { _, new in
                                        let digits = new.filter { $0.isNumber }
                                        if digits != new { amountText = digits }
                                    }
                                if !amountText.isEmpty {
                                    Text("원")
                                        .font(.caption)
                                        .foregroundStyle(theme.textSecondary)
                                }
                            }
                        }
                    }

                    // 기간
                    sectionCard(title: "기간", theme: theme) {
                        VStack(spacing: 0) {
                            rowField(theme: theme) {
                                DatePicker("시작일", selection: $startDate, displayedComponents: .date)
                                    .foregroundStyle(theme.textPrimary)
                                    .tint(theme.primary)
                            }
                            Divider()
                                .background(theme.textSecondary.opacity(0.2))
                                .padding(.horizontal, 16)
                            rowField(theme: theme) {
                                DatePicker("종료일", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .foregroundStyle(theme.textPrimary)
                                    .tint(theme.primary)
                            }
                        }
                    }

                    // 상태
                    sectionCard(title: "상태", theme: theme) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(SponsorshipStatus.allCases, id: \.self) { s in
                                    Button {
                                        Haptic.selection()
                                        withAnimation(.spring(duration: 0.2)) { status = s }
                                    } label: {
                                        SponsorshipStatusBadge(status: s)
                                            .opacity(status == s ? 1 : 0.35)
                                            .scaleEffect(status == s ? 1.08 : 1)
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }

                    // 세부 내용
                    sectionCard(title: "세부 내용", theme: theme) {
                        TextEditor(text: $details)
                            .focused($focusedField, equals: .details)
                            .foregroundStyle(theme.textPrimary)
                            .scrollContentBackground(.hidden)
                            .scrollDisabled(true)
                            .frame(minHeight: 120)
                            .padding(16)
                    }

                    Spacer().frame(height: 20)
                }
                .padding()
            }
            .background(theme.background)
            .navigationTitle(editingSponsorship == nil ? "협찬 추가" : "협찬 편집")
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
            .alert("오류", isPresented: $showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, theme: AppTheme, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(theme.textSecondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
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

    // MARK: - Logic

    private func loadIfEditing() {
        guard let s = editingSponsorship else { return }
        brandName = s.brandName
        productName = s.productName
        details = s.details
        if s.amount > 0 {
            amountText = String(Int(s.amount))
        }
        startDate = s.startDate
        endDate = s.endDate
        status = s.sponsorshipStatus
    }

    private func save() async {
        isLoading = true
        defer { isLoading = false }
        DataManager.shared.errorMessage = nil
        let trimmedBrand = brandName.trimmingCharacters(in: .whitespaces)
        if var updated = editingSponsorship {
            updated.brandName = trimmedBrand
            updated.productName = productName
            updated.details = details
            updated.amount = parsedAmount
            updated.startDate = startDate
            updated.endDate = endDate
            updated.status = status.rawValue
            updated.updatedAt = .now
            await DataManager.shared.updateSponsorship(updated)
        } else {
            await DataManager.shared.createSponsorship(
                brandName: trimmedBrand,
                productName: productName,
                details: details,
                amount: parsedAmount,
                startDate: startDate,
                endDate: endDate,
                status: status
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
