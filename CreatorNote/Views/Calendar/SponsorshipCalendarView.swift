import SwiftUI

struct SponsorshipCalendarView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingAddSheet = false
    @State private var showExportAlert = false
    @State private var exportMessage = ""

    private var sponsorships: [SponsorshipDTO] { DataManager.shared.sponsorships }
    private var calendar: Calendar { Calendar.current }

    private var daysInMonth: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstDay)
        }
    }

    private var firstWeekday: Int {
        guard let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else { return 0 }
        return (calendar.component(.weekday, from: firstDay) + 5) % 7
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy년 M월"
        return f
    }()

    private var monthTitle: String {
        Self.monthFormatter.string(from: currentMonth)
    }

    private func sponsorshipsFor(date: Date) -> [SponsorshipDTO] {
        sponsorships.filter { s in
            let start = calendar.startOfDay(for: s.startDate)
            let end = calendar.startOfDay(for: s.endDate)
            let target = calendar.startOfDay(for: date)
            return target >= start && target <= end
        }
    }

    private func isEndDate(_ date: Date, for sponsorship: SponsorshipDTO) -> Bool {
        calendar.isDate(date, inSameDayAs: sponsorship.endDate)
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    // Month navigation
                    HStack {
                        Button(action: { changeMonth(-1) }) {
                            Image(systemName: "chevron.left")
                                .font(.body.bold())
                                .foregroundStyle(theme.primary)
                                .frame(width: 36, height: 36)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        VStack(spacing: 2) {
                            Text(monthTitle)
                                .font(.title3.bold())
                                .foregroundStyle(theme.textPrimary)
                            Text("협찬 \(sponsorships.filter { !$0.isExpired }.count)건 진행중")
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        Spacer()
                        Button(action: { changeMonth(1) }) {
                            Image(systemName: "chevron.right")
                                .font(.body.bold())
                                .foregroundStyle(theme.primary)
                                .frame(width: 36, height: 36)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Today button
                    if !calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month) {
                        Button {
                            withAnimation {
                                currentMonth = Date()
                                selectedDate = Date()
                            }
                        } label: {
                            Text("오늘")
                                .font(.caption.bold())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(theme.primary.opacity(0.1))
                                .foregroundStyle(theme.primary)
                                .clipShape(Capsule())
                        }
                    }

                    // Weekday headers
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                            Text(day)
                                .font(.caption.bold())
                                .foregroundStyle(day == "토" || day == "일" ? theme.accent : theme.textSecondary)
                        }

                        ForEach(0..<firstWeekday, id: \.self) { _ in
                            Text("")
                        }

                        ForEach(daysInMonth, id: \.self) { date in
                            let sponsors = sponsorshipsFor(date: date)
                            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                            let isToday = calendar.isDateInToday(date)

                            Button(action: {
                                withAnimation(.spring(duration: 0.2)) { selectedDate = date }
                            }) {
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
                                        AnyShapeStyle(theme.primary) :
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

                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedDate, format: .dateTime.month().day().weekday(.wide))
                            .font(.headline)
                            .foregroundStyle(theme.textPrimary)
                            .padding(.horizontal)

                        if !selectedSponsors.isEmpty {
                            ForEach(selectedSponsors) { s in
                                ThemedCard {
                                    HStack {
                                        Circle()
                                            .fill(theme.primary)
                                            .frame(width: 32, height: 32)
                                            .overlay {
                                                Text(String(s.brandName.prefix(1)))
                                                    .font(.caption.bold())
                                                    .foregroundStyle(.white)
                                            }
                                        VStack(alignment: .leading, spacing: 2) {
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
                        } else {
                            HStack {
                                Spacer()
                                Text("이 날에 예정된 협찬이 없습니다")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.textSecondary)
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        }
                    }
                }
                .padding(.top)
                .padding(.bottom, 90)
            }
            .background(theme.background)

            Button { showingAddSheet = true } label: {
                Circle()
                    .fill(theme.primary)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)
            .padding(20)

            } // ZStack
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            let active = sponsorships.filter { !$0.isExpired }
                            if active.isEmpty {
                                exportMessage = "내보낼 협찬이 없습니다"
                                showExportAlert = true
                                return
                            }
                            let count = await CalendarExportHelper.exportAll(sponsorships: active)
                            exportMessage = count > 0
                                ? "\(count)건의 협찬이 캘린더에 추가되었습니다"
                                : "캘린더 접근 권한이 필요합니다"
                            showExportAlert = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(theme.primary)
                    }
                }
            }
            .alert("캘린더 내보내기", isPresented: $showExportAlert) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(exportMessage)
            }
            .refreshable {
                await DataManager.shared.fetchSponsorships()
            }
            .sheet(isPresented: $showingAddSheet) {
                SponsorshipFormView()
            }
        }
    }

    private func changeMonth(_ offset: Int) {
        withAnimation(.spring(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) ?? currentMonth
        }
    }
}
