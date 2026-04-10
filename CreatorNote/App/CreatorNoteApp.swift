import SwiftUI
@preconcurrency import Supabase

@main
struct CreatorNoteApp: App {
    @State private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(themeManager)
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
    @State private var showWorkspaceSetup = false

    var body: some View {
        Group {
            if !authChecked {
                ZStack {
                    themeManager.theme.background.ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(themeManager.theme.primary)
                        Text("Influe")
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundStyle(themeManager.theme.textPrimary)
                    }
                }
            } else if !AuthManager.shared.isAuthenticated {
                LoginView()
            } else if !WorkspaceManager.shared.hasWorkspace {
                WorkspaceSetupView {
                    showWorkspaceSetup = false
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
