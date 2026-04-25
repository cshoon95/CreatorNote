import SwiftUI
@preconcurrency import Supabase

@main
struct InflueApp: App {
    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(themeManager)
                .withToast()
                .onOpenURL { url in
                    Task {
                        try? await SupabaseManager.shared.client.auth.handle(url)
                    }
                }
        }
    }
}

struct RootView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var authChecked = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var skippedWorkspaceSetup = false
    @State private var skippedPendingApproval = false

    var body: some View {
        let wm = WorkspaceManager.shared
        Group {
            if !authChecked {
                SplashView()
            } else if !AuthManager.shared.isAuthenticated {
                LoginView()
            } else if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
            } else if wm.isPendingApproval && !skippedPendingApproval {
                PendingApprovalView {
                    skippedPendingApproval = true
                }
            } else if !wm.hasWorkspace && !skippedWorkspaceSetup {
                WorkspaceSetupView {
                    skippedWorkspaceSetup = true
                }
            } else {
                ContentView()
            }
        }
        .task {
            await AuthManager.shared.checkSession()
            authChecked = true
        }
    }
}

struct SplashView: View {
    @Environment(ThemeManager.self) private var themeManager

    private static let features: [String] = [
        "협찬 일정을 한눈에 관리하세요 📅",
        "정산 내역을 깔끔하게 정리해요 💰",
        "릴스 대본을 스마트하게 작성해요 🎬",
        "워크스페이스로 팀과 함께 일해요 👥",
        "마감 임박 협찬을 놓치지 마세요 ⏰",
        "수수료·세금 자동 계산으로 실수령액 확인 🧾",
        "캘린더로 협찬 기간을 시각화해요 🗓️",
        "업로드 상태를 한 번에 추적해요 📊",
        "태그로 노트를 빠르게 찾아요 🏷️",
        "초대 코드로 파트너와 공유해요 🔗"
    ]

    private let message: String = features.randomElement() ?? "로딩 중..."

    var body: some View {
        let theme = themeManager.theme
        ZStack {
            theme.primary
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    Text("Influe")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    Text(message)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity)
                }

                Spacer()

                ProgressView()
                    .tint(.white.opacity(0.7))
                    .scaleEffect(0.9)
                    .padding(.bottom, 60)
            }
        }
    }
}
