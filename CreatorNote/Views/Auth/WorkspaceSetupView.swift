import SwiftUI

struct WorkspaceSetupView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab = 0
    @State private var workspaceName = ""
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var workspaceNameFocused: Bool
    @FocusState private var inviteCodeFocused: Bool

    var onComplete: () -> Void

    var body: some View {
        let theme = themeManager.theme

        ZStack(alignment: .top) {
            theme.background
                .ignoresSafeArea()

            theme.primary
                .frame(height: 240)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    Spacer().frame(height: 56)

                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)

                    Text("워크스페이스 설정")
                        .font(.system(.largeTitle, design: .rounded).bold())
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                    Text("함께 사용할 공간을 만들어요")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.15))
                        .clipShape(Capsule())

                    Spacer().frame(height: 24)
                }
                .frame(height: 240)

                VStack(spacing: 28) {
                    Picker("", selection: $selectedTab) {
                        Text("새로 만들기").tag(0)
                        Text("초대 코드 입력").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)

                    if selectedTab == 0 {
                        createSection(theme: theme)
                    } else {
                        joinSection(theme: theme)
                    }

                    Spacer()
                }
                .padding(.top, 28)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                )
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func createSection(theme: AppTheme) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("워크스페이스 이름")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(theme.textSecondary)

                HStack {
                    Image(systemName: "building.2")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.primary.opacity(0.7))
                    TextField("예: 우리집 크리에이터", text: $workspaceName)
                        .textFieldStyle(.plain)
                        .focused($workspaceNameFocused)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(theme.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .onTapGesture { workspaceNameFocused = true }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            workspaceNameFocused
                                ? LinearGradient(colors: [theme.primary], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1.5
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: workspaceNameFocused)
            }

            actionButton(
                label: "워크스페이스 만들기",
                icon: "sparkles",
                theme: theme,
                disabled: workspaceName.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                Task { await createWorkspace() }
            }
        }
    }

    private func joinSection(theme: AppTheme) -> some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("초대 코드")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(theme.textSecondary)

                HStack {
                    Image(systemName: "key.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.primary.opacity(0.7))
                    TextField("6자리 코드 입력", text: $inviteCode)
                        .textFieldStyle(.plain)
                        .textInputAutocapitalization(.characters)
                        .focused($inviteCodeFocused)
                        .font(.system(.body, design: .rounded).monospacedDigit())
                        .foregroundStyle(theme.textPrimary)
                        .kerning(inviteCode.isEmpty ? 0 : 3)
                        .onChange(of: inviteCode) { _, newValue in
                            inviteCode = String(newValue.prefix(6)).uppercased()
                        }

                    if !inviteCode.isEmpty {
                        Text("\(inviteCode.count)/6")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(inviteCode.count == 6 ? theme.primary : theme.textSecondary)
                            .animation(.easeInOut, value: inviteCode.count)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(theme.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .contentShape(RoundedRectangle(cornerRadius: 14))
                .onTapGesture { inviteCodeFocused = true }
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            inviteCodeFocused
                                ? LinearGradient(colors: [theme.primary], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1.5
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: inviteCodeFocused)
            }

            actionButton(
                label: "참여하기",
                icon: "arrow.right.circle.fill",
                theme: theme,
                disabled: inviteCode.count != 6
            ) {
                Task { await joinWorkspace() }
            }
        }
    }

    private func actionButton(
        label: String,
        icon: String,
        theme: AppTheme,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let isDisabled = disabled || isLoading
        return Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(label)
                    .font(.system(.body, design: .rounded).bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(isDisabled ? theme.primary.opacity(0.4) : theme.primary)
        }
        .disabled(isDisabled)
    }

    private func createWorkspace() async {
        isLoading = true
        defer { isLoading = false }
        let success = await WorkspaceManager.shared.createWorkspace(name: workspaceName.trimmingCharacters(in: .whitespaces))
        if success {
            await DataManager.shared.fetchAll()
            onComplete()
        } else {
            errorMessage = WorkspaceManager.shared.errorMessage ?? "워크스페이스 생성에 실패했습니다"
            showError = true
        }
    }

    private func joinWorkspace() async {
        isLoading = true
        defer { isLoading = false }
        let success = await WorkspaceManager.shared.joinWithCode(inviteCode)
        if success {
            // pending 상태이므로 DataManager 로드 없이 바로 진행
            onComplete()
        } else {
            errorMessage = WorkspaceManager.shared.errorMessage ?? "참여에 실패했습니다"
            showError = true
        }
    }
}
