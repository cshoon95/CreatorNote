import SwiftUI

struct PendingApprovalView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var isChecking = false
    @State private var showCancelAlert = false
    @State private var dotCount = 0
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    private let dotTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var onSkip: (() -> Void)?

    private var workspaceName: String {
        WorkspaceManager.shared.pendingWorkspace?.name ?? "워크스페이스"
    }

    var body: some View {
        let theme = themeManager.theme
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.12))
                        .frame(width: 120, height: 120)
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 52, weight: .medium))
                        .foregroundStyle(theme.primary)
                }
                .padding(.bottom, 40)

                // Title
                Text("승인 대기 중")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                    .padding(.bottom, 12)

                // Workspace name badge
                HStack(spacing: 6) {
                    Image(systemName: "briefcase.fill")
                        .font(.caption.bold())
                    Text(workspaceName)
                        .font(.system(.subheadline, design: .rounded).bold())
                }
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(theme.primary.opacity(0.1))
                .clipShape(Capsule())
                .padding(.bottom, 20)

                // Description
                Text("방장이 참여 요청을 승인하면\n자동으로 입장됩니다")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 48)
                    .padding(.bottom, 48)

                // Waiting dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index < dotCount ? theme.primary : theme.primary.opacity(0.2))
                            .frame(width: 10, height: 10)
                            .scaleEffect(index < dotCount ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: dotCount)
                    }
                }
                .padding(.bottom, 48)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        Task { await checkStatus() }
                    } label: {
                        HStack(spacing: 8) {
                            if isChecking {
                                ProgressView().tint(theme.primary).scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.bold())
                            }
                            Text("승인 상태 확인")
                                .font(.system(.body, design: .rounded).bold())
                        }
                        .foregroundStyle(theme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isChecking)

                    if let onSkip {
                        Button {
                            onSkip()
                        } label: {
                            Text("홈으로 이동")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(theme.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    Button(role: .destructive) {
                        showCancelAlert = true
                    } label: {
                        Text("요청 취소")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .alert("참여 요청 취소", isPresented: $showCancelAlert) {
            Button("취소하기", role: .destructive) {
                Task { await WorkspaceManager.shared.cancelPendingRequest() }
            }
            Button("계속 대기", role: .cancel) {}
        } message: {
            Text("참여 요청을 취소하면 처음부터 다시 시도해야 합니다.")
        }
        .onReceive(timer) { _ in
            Task { await checkStatus() }
        }
        .onReceive(dotTimer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }

    private func checkStatus() async {
        guard !isChecking else { return }
        isChecking = true
        await WorkspaceManager.shared.checkApprovalStatus()
        isChecking = false
    }
}
