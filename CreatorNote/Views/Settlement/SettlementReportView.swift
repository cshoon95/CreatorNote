import SwiftUI
import Charts

struct SettlementReportView: View {
    @Environment(ThemeManager.self) private var themeManager

    enum PeriodFilter: String, CaseIterable {
        case all = "전체"
        case threeMonths = "3개월"
        case sixMonths = "6개월"
        case oneYear = "1년"

        var months: Int? {
            switch self {
            case .all: return nil
            case .threeMonths: return 3
            case .sixMonths: return 6
            case .oneYear: return 12
            }
        }
    }

    @State private var selectedPeriod: PeriodFilter = .sixMonths

    private var sponsorships: [SponsorshipDTO] { DataManager.shared.sponsorships }
    private var settlements: [SettlementDTO] { DataManager.shared.settlements }

    private var filteredSettlements: [SettlementDTO] {
        guard let months = selectedPeriod.months else { return settlements }
        let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: .now) ?? .now
        return settlements.filter { s in
            if let date = s.settlementDate { return date >= cutoff }
            return s.createdAt >= cutoff
        }
    }

    private var totalRevenue: Double {
        sponsorships
            .filter { $0.sponsorshipStatus == .completed }
            .reduce(0) { $0 + $1.amount }
    }

    private var totalSettlement: Double {
        filteredSettlements.reduce(0) { $0 + $1.netAmount }
    }

    private var unpaidSettlement: Double {
        filteredSettlements.filter { !$0.isPaid }.reduce(0) { $0 + $1.netAmount }
    }

    private var averageAmount: Double {
        let completed = sponsorships.filter { $0.sponsorshipStatus == .completed }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0) { $0 + $1.amount } / Double(completed.count)
    }

    // Monthly data for last 6 months (or filtered period)
    private var monthlyData: [(label: String, amount: Double)] {
        let calendar = Calendar.current
        let monthCount = selectedPeriod.months ?? 12
        return (0..<monthCount).reversed().compactMap { offset -> (String, Double)? in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: .now) else { return nil }
            let components = calendar.dateComponents([.year, .month], from: monthDate)
            let total = filteredSettlements.filter { s in
                let dateToUse = s.settlementDate ?? s.createdAt
                let c = calendar.dateComponents([.year, .month], from: dateToUse)
                return c.year == components.year && c.month == components.month
            }.reduce(0) { $0 + $1.netAmount }
            let formatter = DateFormatter()
            formatter.dateFormat = "M월"
            return (formatter.string(from: monthDate), total)
        }
    }

    // Top 5 brands by total settlement amount
    private var topBrands: [(brand: String, total: Double, count: Int)] {
        var grouped: [String: (total: Double, count: Int)] = [:]
        for s in filteredSettlements {
            let current = grouped[s.brandName] ?? (0, 0)
            grouped[s.brandName] = (current.total + s.netAmount, current.count + 1)
        }
        return grouped
            .map { (brand: $0.key, total: $0.value.total, count: $0.value.count) }
            .sorted { $0.total > $1.total }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        periodPicker(theme: theme)
                            .padding(.horizontal)
                            .padding(.top, 12)

                        summaryCards(theme: theme)
                            .padding(.horizontal)

                        chartSection(theme: theme)
                            .padding(.horizontal)

                        brandRanking(theme: theme)
                            .padding(.horizontal)

                        Spacer().frame(height: 32)
                    }
                }
            }
            .navigationTitle("정산 리포트")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(theme.colorScheme)
        }
    }

    // MARK: - Period Picker

    private func periodPicker(theme: AppTheme) -> some View {
        Picker("기간", selection: $selectedPeriod) {
            ForEach(PeriodFilter.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedPeriod) { _, _ in
            Haptic.selection()
        }
    }

    // MARK: - Summary Cards

    private func summaryCards(theme: AppTheme) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(title: "총 수익", value: totalRevenue.krwFormatted, icon: "chart.line.uptrend.xyaxis", color: theme.primary, theme: theme)
            summaryCard(title: "총 정산", value: totalSettlement.krwFormatted, icon: "wonsign.circle.fill", color: theme.accent, theme: theme)
            summaryCard(title: "미정산", value: unpaidSettlement.krwFormatted, icon: "clock.fill", color: .orange, theme: theme)
            summaryCard(title: "평균 단가", value: averageAmount.krwFormatted, icon: "equal.circle.fill", color: theme.secondary, theme: theme)
        }
    }

    private func summaryCard(title: String, value: String, icon: String, color: Color, theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.subheadline.bold())
                        .foregroundStyle(color)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
    }

    // MARK: - Chart Section

    private func chartSection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("월별 정산 현황")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if monthlyData.allSatisfy({ $0.amount == 0 }) {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.largeTitle)
                            .foregroundStyle(theme.textSecondary.opacity(0.4))
                        Text("정산 데이터가 없습니다")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                Chart {
                    ForEach(monthlyData, id: \.label) { item in
                        BarMark(
                            x: .value("월", item.label),
                            y: .value("금액", item.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: theme.gradient,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text(shortFormatKRW(amount))
                                    .font(.caption2)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(theme.divider)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(.caption2)
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    // MARK: - Brand Ranking

    private func brandRanking(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("브랜드 TOP 5")
                .font(.headline)
                .foregroundStyle(theme.textPrimary)

            if topBrands.isEmpty {
                HStack {
                    Spacer()
                    Text("정산 데이터가 없습니다")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                        .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(topBrands.enumerated()), id: \.offset) { index, brand in
                        brandRow(rank: index + 1, brand: brand.brand, total: brand.total, count: brand.count, theme: theme)
                    }
                }
            }
        }
        .padding(18)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }

    private func brandRow(rank: Int, brand: String, total: Double, count: Int, theme: AppTheme) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rank <= 3 ? theme.primary.opacity(0.15) : theme.surfaceBackground)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundStyle(rank <= 3 ? theme.primary : theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(brand)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                Text("정산 \(count)건")
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Text(total.krwFormatted)
                .font(.subheadline.bold())
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func shortFormatKRW(_ amount: Double) -> String {
        if amount >= 100_000_000 {
            return String(format: "%.0f억", amount / 100_000_000)
        } else if amount >= 10_000 {
            return String(format: "%.0f만", amount / 10_000)
        } else {
            return String(format: "%.0f", amount)
        }
    }
}
