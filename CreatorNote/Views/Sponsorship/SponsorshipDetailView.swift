import SwiftUI
import SwiftData

struct SponsorshipDetailView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Bindable var sponsorship: Sponsorship
    @State private var isEditing = false

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                // Header card
                ThemedCard {
                    VStack(spacing: 16) {
                        HStack {
                            Circle()
                                .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 56, height: 56)
                                .overlay {
                                    Text(String(sponsorship.brandName.prefix(1)))
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)
                                }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sponsorship.brandName)
                                    .font(.title3.bold())
                                    .foregroundStyle(theme.textPrimary)
                                Text(sponsorship.productName)
                                    .font(.subheadline)
                                    .foregroundStyle(theme.textSecondary)
                            }
                            Spacer()
                        }

                        Divider()

                        // Amount
                        HStack {
                            Label("금액", systemImage: "wonsign.circle")
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                            Text(sponsorship.amount.krwFormatted)
                                .font(.headline)
                                .foregroundStyle(theme.primary)
                        }

                        // Period
                        HStack {
                            Label("기간", systemImage: "calendar")
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                            Text("\(formatDate(sponsorship.startDate)) ~ \(formatDate(sponsorship.endDate))")
                                .font(.subheadline)
                                .foregroundStyle(theme.textPrimary)
                        }

                        // D-day
                        HStack {
                            Label("남은 일수", systemImage: "clock")
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                            Text(sponsorship.isExpired ? "만료됨" : "D-\(sponsorship.daysRemaining)")
                                .font(.headline.bold())
                                .foregroundStyle(sponsorship.isExpired ? .red : theme.primary)
                        }

                        // Settlement status
                        HStack {
                            Label("정산", systemImage: "checkmark.circle")
                                .foregroundStyle(theme.textSecondary)
                            Spacer()
                            Toggle("", isOn: $sponsorship.isSettled)
                                .tint(theme.primary)
                        }
                    }
                }
                .padding(.horizontal)

                // Details
                if !sponsorship.details.isEmpty {
                    ThemedCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("세부 내용")
                                .font(.headline)
                                .foregroundStyle(theme.textPrimary)
                            Text(sponsorship.details)
                                .font(.body)
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
        .navigationTitle(sponsorship.brandName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("편집") { isEditing = true }
                    .foregroundStyle(theme.primary)
            }
        }
        .sheet(isPresented: $isEditing) {
            SponsorshipFormView(editingSponsorship: sponsorship)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM.dd"
        return f
    }()

    private func formatDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
}
