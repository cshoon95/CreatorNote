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
                        Text("Influe")
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

                // Login Buttons
                VStack(spacing: 14) {
                    // Apple 로그인
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task { await handleAppleSignIn(result) }
                    }
                    .signInWithAppleButtonStyle(
                        themeManager.currentThemeType == .midnight ? .white : .black
                    )
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)

                    // Google 로그인
                    Button {
                        Task {
                            await performLogin(provider: "google") {
                                await AuthManager.shared.signInWithGoogle()
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)

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
                        .padding(.horizontal, 20)
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        }
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    }
                    .disabled(isLoading)
                    .opacity(isLoading && loadingProvider != "google" ? 0.5 : 1.0)
                }
                .padding(.horizontal, 24)

                Text("로그인 시 서비스 이용약관에 동의하게 됩니다.")
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary.opacity(0.6))
                    .padding(.top, 16)

                Spacer()
                    .frame(height: 50)
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
