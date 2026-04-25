import SwiftUI

struct WorkspaceSetupView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var mode: SetupMode = .none
    @State private var workspaceName = ""
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var fieldFocused: Bool

    enum SetupMode {
        case none, create, join
    }

    var onComplete: () -> Void

    var body: some View {
        let theme = themeManager.theme

        ScrollView {
            VStack(spacing: 0) {
                // Top illustration
                VStack(spacing: 16) {
                    Spacer().frame(height: 48)

                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.1))
                            .frame(width: 100, height: 100)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(theme.primary)
                    }

                    Text("워크스페이스")
                        .font(.system(.title, design: .rounded).bold())
                        .foregroundStyle(theme.textPrimary)

                    Text("팀원과 함께 협찬을 관리할 공간이에요")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.textSecondary)

                    Spacer().frame(height: 8)
                }

                // Cards
                VStack(spacing: 14) {
                    // Create card
                    optionCard(
                        icon: "plus.square.fill",
                        title: "새 워크스페이스 만들기",
                        subtitle: "직접 만들고 팀원을 초대하세요",
                        isSelected: mode == .create,
                        theme: theme
                    ) {
                        withAnimation(.spring(duration: 0.35)) {
                            mode = mode == .create ? .none : .create
                            fieldFocused = mode == .create
                        }
                    }

                    if mode == .create {
                        createForm(theme: theme)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Join card
                    optionCard(
                        icon: "ticket.fill",
                        title: "초대 코드로 참여하기",
                        subtitle: "받은 코드를 입력해 합류하세요",
                        isSelected: mode == .join,
                        theme: theme
                    ) {
                        withAnimation(.spring(duration: 0.35)) {
                            mode = mode == .join ? .none : .join
                            fieldFocused = mode == .join
                        }
                    }

                    if mode == .join {
                        joinForm(theme: theme)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 40)

                Button {
                    onComplete()
                } label: {
                    Text("나중에 할게요")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(theme.textSecondary.opacity(0.7))
                        .underline()
                }
                .padding(.bottom, 40)
            }
        }
        .background(theme.background.ignoresSafeArea())
        .preferredColorScheme(theme.colorScheme)
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Option Card

    private func optionCard(
        icon: String,
        title: String,
        subtitle: String,
        isSelected: Bool,
        theme: AppTheme,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? theme.primary : theme.primary.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : theme.primary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundStyle(theme.textPrimary)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "chevron.up" : "chevron.down")
                    .font(.caption.bold())
                    .foregroundStyle(theme.textSecondary)
            }
            .padding(16)
            .background(theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? theme.primary.opacity(0.3) : theme.divider, lineWidth: 1)
            )
            .shadow(color: isSelected ? theme.primary.opacity(0.08) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create Form

    private func createForm(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "building.2")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.primary)
                    .frame(width: 20)
                TextField("워크스페이스 이름을 입력하세요", text: $workspaceName)
                    .textFieldStyle(.plain)
                    .focused($fieldFocused)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
            }
            .padding(16)
            .background(theme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(fieldFocused && mode == .create ? theme.primary.opacity(0.5) : .clear, lineWidth: 1.5)
            )

            Button {
                Task { await createWorkspace() }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("만들기")
                        .font(.system(.body, design: .rounded).bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(workspaceName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
                    ? theme.primary.opacity(0.35) : theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(workspaceName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Join Form

    private func joinForm(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(theme.primary)
                    .frame(width: 20)
                TextField("6자리 초대 코드", text: $inviteCode)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.characters)
                    .focused($fieldFocused)
                    .font(.system(.body, design: .rounded).monospacedDigit())
                    .foregroundStyle(theme.textPrimary)
                    .kerning(inviteCode.isEmpty ? 0 : 4)
                    .onChange(of: inviteCode) { _, newValue in
                        inviteCode = String(newValue.prefix(6)).uppercased()
                    }

                if !inviteCode.isEmpty {
                    Text("\(inviteCode.count)/6")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(inviteCode.count == 6 ? theme.primary : theme.textSecondary)
                }
            }
            .padding(16)
            .background(theme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(fieldFocused && mode == .join ? theme.primary.opacity(0.5) : .clear, lineWidth: 1.5)
            )

            Button {
                Task { await joinWorkspace() }
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text("참여하기")
                        .font(.system(.body, design: .rounded).bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(.white)
                .background(inviteCode.count != 6 || isLoading
                    ? theme.primary.opacity(0.35) : theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(inviteCode.count != 6 || isLoading)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Actions

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
            onComplete()
        } else {
            errorMessage = WorkspaceManager.shared.errorMessage ?? "참여에 실패했습니다"
            showError = true
        }
    }
}
