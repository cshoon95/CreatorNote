import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var isLoading = false
    @State private var loadingProvider: String?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // 로고 섹션
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles.rectangle.stack")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(Color(hex: "8B5CF6"))

                        Text("Influe")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Text("인플루언서를 위한 스마트 관리")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // 로그인 버튼 섹션
                    VStack(spacing: 12) {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            Task { await handleAppleSignIn(result) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 52)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            Task {
                                await performLogin(provider: "google") {
                                    await AuthManager.shared.signInWithGoogle()
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "g.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: "4285F4"))

                                Text("Google로 로그인")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)

                                if loadingProvider == "google" {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                }
                            }
                            .frame(height: 52)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                        }
                        .disabled(isLoading)
                        .opacity(isLoading && loadingProvider != "google" ? 0.5 : 1.0)

                        HStack(spacing: 0) {
                            Text("로그인 시 ")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Link("개인정보처리방침", destination: URL(string: "https://gilded-basin-4bf.notion.site/Influe-341b9edfc50880c5b571f566a637d578")!)
                                .font(.caption2)
                            Text(" 및 ")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            Link("이용약관", destination: URL(string: "https://gilded-basin-4bf.notion.site/Influe-341b9edfc50880a9ab29d6ac3439bbde")!)
                                .font(.caption2)
                            Text("에 동의하게 됩니다.")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom + 16 : 40)
                }
            }
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ProgressView()
                    .scaleEffect(1.1)
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
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
            let nsError = error as NSError
            let ignoredCodes = [
                ASAuthorizationError.canceled.rawValue,
                ASAuthorizationError.unknown.rawValue,
            ]
            if !ignoredCodes.contains(nsError.code) {
                errorMessage = "Apple 로그인에 실패했습니다. 다시 시도해주세요."
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
