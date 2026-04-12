import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var isLoading = false
    @State private var loadingProvider: String?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        let theme = themeManager.theme
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: theme.gradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.18))
                                .frame(width: 100, height: 100)

                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)

                        VStack(spacing: 10) {
                            Text("Influe")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("인플루언서를 위한 스마트 관리")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .frame(height: geo.size.height * 0.52, alignment: .center)

                    Spacer()
                }

                loginCard(theme: theme, geo: geo)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay {
            if isLoading {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(theme.primary)
                    .padding(24)
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: theme.primary.opacity(0.2), radius: 12)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isLoading)
        .alert("로그인 오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
    }

    private func loginCard(theme: AppTheme, geo: GeometryProxy) -> some View {
        VStack(spacing: 24) {
            RoundedRectangle(cornerRadius: 3)
                .fill(theme.textSecondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 14)

            VStack(spacing: 6) {
                Text("시작하기")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)

                Text("계정으로 빠르게 로그인하세요")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(.top, 4)

            VStack(spacing: 14) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task { await handleAppleSignIn(result) }
                }
                .signInWithAppleButtonStyle(
                    themeManager.currentThemeType == .midnight ? .white : .black
                )
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                Button {
                    Task {
                        await performLogin(provider: "google") {
                            await AuthManager.shared.signInWithGoogle()
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "F1F3F4"))
                                .frame(width: 32, height: 32)
                            Image(systemName: "g.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color(hex: "4285F4"))
                        }

                        Text("Google로 계속하기")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)

                        Spacer()

                        if loadingProvider == "google" {
                            ProgressView()
                                .tint(Color(hex: "3C4043"))
                                .scaleEffect(0.8)
                        }
                    }
                    .foregroundStyle(Color(hex: "3C4043"))
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading)
                .opacity(isLoading && loadingProvider != "google" ? 0.5 : 1.0)
            }

            Text("로그인 시 서비스 이용약관에 동의하게 됩니다.")
                .font(.caption2)
                .foregroundStyle(theme.textSecondary.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom : 16)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 8)
        .background(
            theme.cardBackground
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 28,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 28
                    )
                )
                .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: -4)
        )
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                isLoading = true
                loadingProvider = "apple"
                defer {
                    isLoading = false
                    loadingProvider = nil
                }
                await AuthManager.shared.signInWithApple(credential: credential)
                if let error = AuthManager.shared.errorMessage {
                    errorMessage = error
                    showError = true
                }
            }
        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func performLogin(provider: String, action: () async -> Void) async {
        isLoading = true
        loadingProvider = provider
        defer {
            isLoading = false
            loadingProvider = nil
        }
        await action()
        if let error = AuthManager.shared.errorMessage {
            errorMessage = error
            showError = true
        }
    }
}
