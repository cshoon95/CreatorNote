import SwiftUI

struct ProfileView: View {
    @Environment(ThemeManager.self) private var themeManager

    @State private var displayName = ""
    @State private var isLoading = false
    @State private var isSigningOut = false
    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showDeleteSuccess = false

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                profileHeader(theme: theme)
                signOutSection(theme: theme)
                deleteAccountSection(theme: theme)
            }
            .padding()
        }
        .background(theme.background)
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("로그아웃", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
            Button("로그아웃", role: .destructive) {
                Task { await signOut() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
        .confirmationDialog("계정 탈퇴", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("탈퇴하기", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다. 정말 탈퇴하시겠습니까?")
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .alert("탈퇴 완료", isPresented: $showDeleteSuccess) {
            Button("확인") {
                AuthManager.shared.isAuthenticated = false
            }
        } message: {
            Text("계정이 성공적으로 삭제되었습니다.")
        }
        .task {
            await loadProfile()
        }
    }

    private func profileHeader(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)

                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(displayName.isEmpty ? "사용자" : displayName)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: theme.primary.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private func signOutSection(theme: AppTheme) -> some View {
        Button {
            showSignOutConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isSigningOut {
                    ProgressView()
                        .tint(.red)
                        .scaleEffect(0.8)
                }
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("로그아웃")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isSigningOut)
        .padding(.top, 8)
    }

    private func deleteAccountSection(theme: AppTheme) -> some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isDeleting {
                    ProgressView()
                        .tint(theme.textSecondary)
                        .scaleEffect(0.8)
                }
                Text("계정 탈퇴")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundStyle(theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .disabled(isDeleting)
    }

    // MARK: - Actions

    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        if let profile = AuthManager.shared.currentProfile {
            displayName = profile.displayName ?? ""
        }
    }

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        await AuthManager.shared.signOut()
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        await AuthManager.shared.deleteAccountData()
        if AuthManager.shared.errorMessage == nil {
            showDeleteSuccess = true
        } else {
            errorMessage = AuthManager.shared.errorMessage
            showError = true
        }
    }
}
