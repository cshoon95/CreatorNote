import SwiftUI
import SwiftData

struct SponsorshipCalendarView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sponsorship.endDate) private var sponsorships: [Sponsorship]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    private var calendar: Calendar { Calendar.current }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    private var firstWeekday: Int {
        let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        return (calendar.component(.weekday, from: firstDay) + 5) % 7 // Monday start
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        return formatter.string(from: currentMonth)
    }

    private func sponsorshipsFor(date: Date) -> [Sponsorship] {
        sponsorships.filter { s in
            let start = calendar.startOfDay(for: s.startDate)
            let end = calendar.startOfDay(for: s.endDate)
            let target = calendar.startOfDay(for: date)
            return target >= start && target <= end
        }
    }

    private func isEndDate(_ date: Date, for sponsorship: Sponsorship) -> Bool {
        calendar.isDate(date, inSameDayAs: sponsorship.endDate)
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month navigation
                    HStack {
                        Button(action: { changeMonth(-1) }) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(theme.primary)
                        }
                        Spacer()
                        Text(monthTitle)
                            .font(.title3.bold())
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Button(action: { changeMonth(1) }) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(theme.primary)
                        }
                    }
                    .padding(.horizontal)

                    // Weekday headers
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                            Text(day)
                                .font(.caption.bold())
                                .foregroundStyle(theme.textSecondary)
                        }

                        // Empty cells for alignment
                        ForEach(0..<firstWeekday, id: \.self) { _ in
                            Text("")
                        }

                        // Days
                        ForEach(daysInMonth, id: \.self) { date in
                            let sponsors = sponsorshipsFor(date: date)
                            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                            let isToday = calendar.isDateInToday(date)

                            Button(action: { selectedDate = date }) {
                                VStack(spacing: 2) {
                                    Text("\(calendar.component(.day, from: date))")
                                        .font(.subheadline)
                                        .fontWeight(isToday ? .bold : .regular)
                                        .foregroundStyle(
                                            isSelected ? .white :
                                            isToday ? theme.primary :
                                            theme.textPrimary
                                        )

                                    if !sponsors.isEmpty {
                                        HStack(spacing: 2) {
                                            ForEach(sponsors.prefix(3)) { s in
                                                Circle()
                                                    .fill(isEndDate(date, for: s) ? Color.red : theme.accent)
                                                    .frame(width: 4, height: 4)
                                            }
                                        }
                                    } else {
                                        Spacer().frame(height: 4)
                                    }
                                }
                                .frame(width: 36, height: 40)
                                .background(
                                    isSelected ?
                                        AnyShapeStyle(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)) :
                                        AnyShapeStyle(Color.clear)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    // Selected date details
                    let selectedSponsors = sponsorshipsFor(date: selectedDate)
                    if !selectedSponsors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selectedDate, format: .dateTime.month().day().weekday(.wide))
                                .font(.headline)
                                .foregroundStyle(theme.textPrimary)
                                .padding(.horizontal)

                            ForEach(selectedSponsors) { s in
                                ThemedCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(s.brandName)
                                                .font(.subheadline.bold())
                                                .foregroundStyle(theme.textPrimary)
                                            Text(s.productName)
                                                .font(.caption)
                                                .foregroundStyle(theme.textSecondary)
                                        }
                                        Spacer()
                                        if isEndDate(selectedDate, for: s) {
                                            Text("마감일")
                                                .font(.caption.bold())
                                                .foregroundStyle(.red)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.red.opacity(0.1))
                                                .clipShape(Capsule())
                                        } else {
                                            Text("D-\(s.daysRemaining)")
                                                .font(.caption.bold())
                                                .foregroundStyle(theme.primary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        Text("이 날에 예정된 협찬이 없습니다")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                            .padding(.top, 20)
                    }
                }
                .padding(.vertical)
            }
            .background(theme.background)
            .navigationTitle("캘린더")
        }
    }

    private func changeMonth(_ offset: Int) {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
        }
    }
}
