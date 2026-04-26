import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab: Tab = .home
    @State private var navigationResetID = UUID()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .separator
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

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
        ZStack(alignment: .bottom) {
            // 콘텐츠 영역
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        DashboardView()
                            .id(navigationResetID)
                    }
                case .sponsorship:
                    NavigationStack {
                        SponsorshipListView()
                    }
                case .settlement:
                    NavigationStack {
                        SettlementListView()
                    }
                case .calendar:
                    NavigationStack {
                        SponsorshipCalendarView()
                    }
                case .notes:
                    NavigationStack {
                        NotesTabView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 56)

            // 커스텀 탭바
            HStack {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        if selectedTab == tab {
                            navigationResetID = UUID()
                        }
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(selectedTab == tab ? theme.primary : Color.gray)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 2)
            .background(
                Rectangle()
                    .fill(theme.cardBackground)
                    .shadow(color: .black.opacity(0.08), radius: 4, y: -2)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .tint(theme.primary)
        .withToast()
        .withCustomAlert()
        .overlay(alignment: .bottom) {
            if let msg = DataManager.shared.errorMessage {
                Text(msg)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.red.gradient, in: Capsule())
                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
