import SwiftUI

struct OnboardingView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var currentPage = 0
    var onDismiss: () -> Void

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "gift.fill",
            title: "협찬 관리",
            subtitle: "협찬 일정과 브랜드를 한눈에 관리하세요"
        ),
        OnboardingPage(
            icon: "wonsign.circle.fill",
            title: "정산 추적",
            subtitle: "수익과 정산 내역을 깔끔하게 정리해요"
        ),
        OnboardingPage(
            icon: "note.text",
            title: "릴스 노트",
            subtitle: "대본과 캡션을 스마트하게 작성하세요"
        ),
        OnboardingPage(
            icon: "person.2.fill",
            title: "팀 협업",
            subtitle: "워크스페이스로 팀과 함께 일하세요"
        )
    ]

    var body: some View {
        let theme = themeManager.theme
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button {
                            Haptic.selection()
                            dismiss()
                        } label: {
                            Text("건너뛰기")
                                .font(.subheadline)
                                .foregroundStyle(theme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .frame(height: 48)

                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page, theme: theme)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicator dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? theme.primary : theme.primary.opacity(0.25))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Action button
                if currentPage == pages.count - 1 {
                    Button {
                        Haptic.success()
                        dismiss()
                    } label: {
                        Text("시작하기")
                            .font(.headline)
                            .foregroundStyle(theme.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Button {
                        Haptic.selection()
                        withAnimation {
                            currentPage += 1
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("다음")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(theme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                }
            }
        }
    }

    private func dismiss() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        onDismiss()
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let theme: AppTheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Gradient icon circle
            ZStack {
                Circle()
                    .fill(theme.primary)
                    .frame(width: 140, height: 140)
                    .shadow(color: theme.primary.opacity(0.35), radius: 24, y: 12)

                Image(systemName: page.icon)
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 48)

            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(theme.textPrimary)
                .padding(.bottom, 16)

            Text(page.subtitle)
                .font(.title3)
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
