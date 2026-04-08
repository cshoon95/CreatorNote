import SwiftUI

struct ProfileView: View {
    @Environment(ThemeManager.self) private var themeManager

    @State private var displayName = ""
    @State private var email = ""
    @State private var provider = ""
    @State private var isLoading = false
    @State private var isSigningOut = false
    @State private var showSignOutConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                profileHeader(theme: theme)

                // Account Info
                accountInfoSection(theme: theme)

                // Sign Out
                signOutSection(theme: theme)
            }
            .padding()
        }
        .background(theme.background)
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "로그아웃",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("로그아웃", role: .destructive) {
                Task { await signOut() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("정말 로그아웃 하시겠습니까?")
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .task {
            await loadProfile()
        }
    }

    @ViewBuilder
    private func profileHeader(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)

                Text(String(displayName.prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(displayName.isEmpty ? "사용자" : displayName)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(theme.textPrimary)

                if !email.isEmpty {
                    Text(email)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: theme.primary.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func accountInfoSection(theme: AppTheme) -> some View {
        ThemedCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person.text.rectangle.fill")
                        .font(.title3)
                        .foregroundStyle(theme.primary)
                    Text("계정 정보")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                }

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 8)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 12) {
                        infoRow(label: "이름", value: displayName.isEmpty ? "-" : displayName, theme: theme)
                        Divider()
                            .overlay(theme.surfaceBackground)
                        infoRow(label: "이메일", value: email.isEmpty ? "-" : email, theme: theme)
                        Divider()
                            .overlay(theme.surfaceBackground)
                        infoRow(
                            label: "로그인 방식",
                            value: providerDisplayName,
                            theme: theme
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func infoRow(label: String, value: String, theme: AppTheme) -> some View {
        HStack {
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(theme.textPrimary)
        }
    }

    @ViewBuilder
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

    // MARK: - Helpers

    private var providerDisplayName: String {
        switch provider.lowercased() {
        case "kakao": return "카카오"
        case "google": return "구글"
        case "naver": return "네이버"
        default: return provider.isEmpty ? "-" : provider
        }
    }

    // MARK: - Actions

    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        if let profile = AuthManager.shared.currentProfile {
            displayName = profile.displayName ?? ""
            provider = profile.provider ?? ""
        }
        if let user = AuthManager.shared.currentUser {
            email = user.email ?? ""
        }
    }

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        await AuthManager.shared.signOut()
    }
}
