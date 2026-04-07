import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "홈"
        case sponsorship = "협찬"
        case settlement = "정산"
        case calendar = "캘린더"
        case notes = "노트"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .sponsorship: return "gift.fill"
            case .settlement: return "wonsign.circle.fill"
            case .calendar: return "calendar"
            case .notes: return "note.text"
            }
        }
    }

    var body: some View {
        let theme = themeManager.theme
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .home:
                        DashboardView()
                    case .sponsorship:
                        SponsorshipListView()
                    case .settlement:
                        SettlementListView()
                    case .calendar:
                        SponsorshipCalendarView()
                    case .notes:
                        NotesTabView()
                    }
                }
                .tabItem {
                    Image(systemName: tab.icon)
                    Text(tab.rawValue)
                }
                .tag(tab)
            }
        }
        .tint(theme.primary)
    }
}
