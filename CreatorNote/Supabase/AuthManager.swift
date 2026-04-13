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

    // MARK: - Apple Sign In

    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            errorMessage = "Apple 로그인 토큰을 가져올 수 없습니다."
            return
        }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )
            currentUser = session.user
            isAuthenticated = true

            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            await fetchOrCreateProfile(
                displayName: name.isEmpty ? nil : name,
                provider: "apple"
            )
            await restoreWorkspace()
        } catch {
            errorMessage = "Apple 로그인에 실패했습니다: \(error.localizedDescription)"
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
                redirectTo: URL(string: "influe://auth/callback")
            )
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            await fetchOrCreateProfile(provider: "google")
            await restoreWorkspace()
        } catch {
            errorMessage = "Google 로그인에 실패했습니다: \(error.localizedDescription)"
        }
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

    // MARK: - Delete Account

    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Get current session JWT for authorization
            let session = try await supabase.auth.session
            let accessToken = session.accessToken

            // Call the Edge Function which handles full account deletion
            let url = URL(string: "https://wrnglzfsgoujboyjomuu.supabase.co/functions/v1/delete-account")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "Unknown error"
                errorMessage = "계정 삭제에 실패했습니다: \(body)"
                return
            }

            // Sign out locally after successful server-side deletion
            try? await supabase.auth.signOut()

            currentUser = nil
            currentProfile = nil
            isAuthenticated = false
            UserDefaults.standard.removeObject(forKey: "current_workspace_id")
            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")

            // 로컬 캐시 삭제
            let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("DataCache")
            try? FileManager.default.removeItem(at: cacheDir)
        } catch {
            errorMessage = "계정 삭제에 실패했습니다: \(error.localizedDescription)"
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

    private func fetchOrCreateProfile(displayName: String? = nil, provider: String = "google") async {
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
                let name = displayName
                    ?? user.userMetadata["full_name"]?.value as? String
                    ?? user.userMetadata["name"]?.value as? String
                let newProfile = Profile(
                    id: user.id,
                    displayName: name,
                    avatarUrl: user.userMetadata["avatar_url"]?.value as? String,
                    provider: provider,
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
