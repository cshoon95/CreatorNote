import Foundation
@preconcurrency import Supabase
import AuthenticationServices

@MainActor @Observable
final class AuthManager {
    static let shared = AuthManager()

    var currentUser: User?
    var currentProfile: Profile?
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private init() {}

    // MARK: - Session

    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            await fetchProfile()
            await restoreWorkspace()
        } catch {
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "creatornote://auth/callback")
            )
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            await fetchOrCreateProfile()
            await restoreWorkspace()
        } catch {
            errorMessage = "Google 로그인에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Kakao Sign In (Placeholder)

    func signInWithKakao() async {
        errorMessage = "카카오 로그인은 준비중입니다."
    }

    // MARK: - Naver Sign In (Placeholder)

    func signInWithNaver() async {
        errorMessage = "네이버 로그인은 준비중입니다."
    }

    // MARK: - Sign Out

    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
            UserDefaults.standard.removeObject(forKey: "current_workspace_id")
        } catch {
            errorMessage = "로그아웃에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Profile

    private func fetchProfile() async {
        guard let userId = currentUser?.id else { return }

        do {
            let profile: Profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            currentProfile = profile
        } catch {
            currentProfile = nil
        }
    }

    private func fetchOrCreateProfile() async {
        guard let user = currentUser else { return }

        do {
            let profiles: [Profile] = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: user.id.uuidString)
                .execute()
                .value

            if let existing = profiles.first {
                currentProfile = existing
            } else {
                let newProfile = Profile(
                    id: user.id,
                    displayName: user.userMetadata["full_name"]?.value as? String,
                    avatarUrl: user.userMetadata["avatar_url"]?.value as? String,
                    provider: "google",
                    createdAt: Date()
                )
                try await supabase
                    .from("profiles")
                    .insert(newProfile)
                    .execute()
                currentProfile = newProfile
            }
        } catch {
            errorMessage = "프로필 로딩에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Workspace Restore

    private func restoreWorkspace() async {
        if let storedId = UserDefaults.standard.string(forKey: "current_workspace_id"),
           let uuid = UUID(uuidString: storedId) {
            await WorkspaceManager.shared.selectWorkspace(id: uuid)
        } else {
            await WorkspaceManager.shared.fetchWorkspaces()
            if let first = WorkspaceManager.shared.workspaces.first {
                await WorkspaceManager.shared.selectWorkspace(id: first.id)
            }
        }
    }
}
