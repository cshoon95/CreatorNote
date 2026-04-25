import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab: Tab = .home
    @State private var navigationResetID = UUID()

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
        TabView(selection: tabSelection) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .home:
                        DashboardView()
                            .id(tab == .home ? navigationResetID : UUID())
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
        .overlay(alignment: .top) {
            if let msg = DataManager.shared.errorMessage {
                Text(msg)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.red.gradient, in: Capsule())
                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: DataManager.shared.errorMessage)
        .task {
            await DataManager.shared.fetchAll()
        }
    }

    private var tabSelection: Binding<Tab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == selectedTab {
                    // 같은 탭 재선택 → 루트로 리셋
                    navigationResetID = UUID()
                }
                selectedTab = newTab
            }
        )
    }
}
