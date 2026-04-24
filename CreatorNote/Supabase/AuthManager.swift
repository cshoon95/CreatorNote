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
            clearAuthState()
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
                credentials: .init(provider: .apple, idToken: tokenString)
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
        } catch let error as NSError where error.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" && error.code == 1 {
            // 사용자가 로그인을 취소한 경우 무시
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
            clearAuthState()
            ToastManager.shared.show("로그아웃되었습니다", icon: "rectangle.portrait.and.arrow.right")
        } catch {
            errorMessage = "로그아웃에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete Account

    func deleteAccountData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let accessToken = try await supabase.auth.session.accessToken

            var request = URLRequest(url: URL(string: "https://wrnglzfsgoujboyjomuu.supabase.co/functions/v1/delete-account")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                errorMessage = "계정 삭제에 실패했습니다: \(String(data: data, encoding: .utf8) ?? "Unknown error")"
                return
            }

            try? await supabase.auth.signOut()
            clearAuthState()
            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")

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
                    ?? "사용자"
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

    // MARK: - Update Profile

    func updateDisplayName(_ name: String) async {
        guard let userId = currentUser?.id else { return }
        errorMessage = nil
        do {
            try await supabase
                .from("profiles")
                .update(["display_name": name])
                .eq("id", value: userId.uuidString)
                .execute()
            currentProfile?.displayName = name
        } catch {
            errorMessage = "닉네임 변경에 실패했습니다: \(error.localizedDescription)"
        }
    }

    // MARK: - Private

    private func clearAuthState() {
        currentUser = nil
        currentProfile = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: "current_workspace_id")
    }

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
