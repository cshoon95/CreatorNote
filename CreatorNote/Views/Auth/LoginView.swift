import SwiftUI

struct LoginView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var isLoading = false
    @State private var loadingProvider: String?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        let theme = themeManager.theme
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App Logo & Title
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
                            .frame(width: 100, height: 100)
                            .shadow(color: theme.primary.opacity(0.3), radius: 20, x: 0, y: 10)

                        Image(systemName: "note.text")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(.white)
                    }

                    VStack(spacing: 8) {
                        Text("Creator Note")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: theme.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("인플루언서를 위한 스마트 관리 앱")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Spacer()

                // Social Login Buttons
                VStack(spacing: 14) {
                    // 카카오 로그인
                    socialLoginButton(
                        provider: "kakao",
                        title: "카카오 로그인",
                        backgroundColor: Color(hex: "FEE500"),
                        foregroundColor: Color(hex: "191919"),
                        iconName: "message.fill"
                    ) {
                        await performLogin(provider: "kakao") {
                            try await AuthManager.shared.signInWithKakao()
                        }
                    }

                    // 구글 로그인
                    socialLoginButton(
                        provider: "google",
                        title: "구글 로그인",
                        backgroundColor: .white,
                        foregroundColor: Color(hex: "3C4043"),
                        iconName: "g.circle.fill",
                        hasBorder: true
                    ) {
                        await performLogin(provider: "google") {
                            try await AuthManager.shared.signInWithGoogle()
                        }
                    }

                    // 네이버 로그인
                    socialLoginButton(
                        provider: "naver",
                        title: "네이버 로그인",
                        backgroundColor: Color(hex: "03C75A"),
                        foregroundColor: .white,
                        iconName: "n.circle.fill"
                    ) {
                        await performLogin(provider: "naver") {
                            try await AuthManager.shared.signInWithNaver()
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 60)
            }

            // Loading Overlay
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(theme.primary)
                    .padding(24)
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: theme.primary.opacity(0.15), radius: 10)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
        .alert("로그인 오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
    }

    @ViewBuilder
    private func socialLoginButton(
        provider: String,
        title: String,
        backgroundColor: Color,
        foregroundColor: Color,
        iconName: String,
        hasBorder: Bool = false,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.title3)

                Text(title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)

                Spacer()

                if loadingProvider == provider {
                    ProgressView()
                        .tint(foregroundColor)
                        .scaleEffect(0.8)
                }
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, 20)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                if hasBorder {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
            }
            .shadow(color: backgroundColor.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .disabled(isLoading)
        .opacity(isLoading && loadingProvider != provider ? 0.5 : 1.0)
    }

    private func performLogin(provider: String, action: () async throws -> Void) async {
        isLoading = true
        loadingProvider = provider
        defer {
            isLoading = false
            loadingProvider = nil
        }
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
