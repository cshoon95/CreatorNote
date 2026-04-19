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
                // 배경: 밝은 파스텔 그라데이션
                LinearGradient(
                    colors: [
                        Color(hex: "F0EEFF"),
                        Color(hex: "FAE8FF"),
                        Color(hex: "E8F4FF")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 장식 블러 원들
                Circle()
                    .fill(Color(hex: "C4B5FD").opacity(0.35))
                    .frame(width: 320)
                    .offset(x: -80, y: -geo.size.height * 0.32)
                    .blur(radius: 70)

                Circle()
                    .fill(Color(hex: "F9A8D4").opacity(0.3))
                    .frame(width: 280)
                    .offset(x: 120, y: -geo.size.height * 0.22)
                    .blur(radius: 60)

                Circle()
                    .fill(Color(hex: "BAE6FD").opacity(0.25))
                    .frame(width: 220)
                    .offset(x: -60, y: geo.size.height * 0.28)
                    .blur(radius: 50)

                // 메인 레이아웃
                VStack(spacing: 0) {
                    Spacer()

                    // 로고 섹션
                    VStack(spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "C4B5FD"), Color(hex: "F9A8D4")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 96, height: 96)
                                .shadow(color: Color(hex: "A78BFA").opacity(0.4), radius: 24, y: 10)

                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.system(size: 42, weight: .medium))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 8) {
                            Text("Influe")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "1E1B4B"))

                            Text("인플루언서를 위한 스마트 관리")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color(hex: "8B83A3"))

                            Text("✦ v2.0")
                                .font(.caption.bold())
                                .foregroundStyle(Color(hex: "8B5CF6"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color(hex: "8B5CF6").opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    // 로그인 버튼 섹션
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                Task { await handleAppleSignIn(result) }
                            }
                            .signInWithAppleButtonStyle(.black)
                            .frame(height: 56)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.12), radius: 12, y: 4)

                            Button {
                                Task {
                                    await performLogin(provider: "google") {
                                        await AuthManager.shared.signInWithGoogle()
                                    }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color(hex: "4285F4"))

                                    Text("Google로 계속하기")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color(hex: "1E1B4B"))

                                    Spacer()

                                    if loadingProvider == "google" {
                                        ProgressView()
                                            .tint(Color(hex: "8B5CF6"))
                                            .scaleEffect(0.8)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .background(.white.opacity(0.72))
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(.white.opacity(0.6), lineWidth: 1)
                                }
                                .shadow(color: Color(hex: "A78BFA").opacity(0.12), radius: 10, y: 4)
                            }
                            .disabled(isLoading)
                            .opacity(isLoading && loadingProvider != "google" ? 0.5 : 1.0)
                        }

                        HStack(spacing: 0) {
                            Text("로그인 시 ")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "8B83A3").opacity(0.8))
                            Link("개인정보처리방침", destination: URL(string: "https://gilded-basin-4bf.notion.site/Influe-341b9edfc50880c5b571f566a637d578")!)
                                .font(.caption2)
                            Text(" 및 ")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "8B83A3").opacity(0.8))
                            Link("이용약관", destination: URL(string: "https://gilded-basin-4bf.notion.site/Influe-341b9edfc50880a9ab29d6ac3439bbde")!)
                                .font(.caption2)
                            Text("에 동의하게 됩니다.")
                                .font(.caption2)
                                .foregroundStyle(Color(hex: "8B83A3").opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom + 16 : 40)
                }
            }
        }
        .overlay {
            if isLoading {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)

                ProgressView()
                    .scaleEffect(1.2)
                    .tint(Color(hex: "8B5CF6"))
                    .padding(24)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color(hex: "A78BFA").opacity(0.2), radius: 16)
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
