import SwiftUI

struct WorkspaceSetupView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab = 0
    @State private var workspaceName = ""
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var onComplete: () -> Void

    var body: some View {
        let theme = themeManager.theme
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                VStack(spacing: 8) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(
                            LinearGradient(colors: theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("워크스페이스 설정")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundStyle(theme.textPrimary)
                    Text("함께 사용할 공간을 만들어보세요")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                }

                Picker("", selection: $selectedTab) {
                    Text("새로 만들기").tag(0)
                    Text("초대 코드 입력").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                if selectedTab == 0 {
                    createSection(theme: theme)
                } else {
                    joinSection(theme: theme)
                }

                Spacer()
            }
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func createSection(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("워크스페이스 이름")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(theme.textSecondary)
                TextField("예: 우리집 크리에이터", text: $workspaceName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button(action: { Task { await createWorkspace() } }) {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("워크스페이스 만들기")
                        .font(.system(.body, design: .rounded).bold())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: theme.gradient, startPoint: .leading, endPoint: .trailing))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(workspaceName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            .opacity(workspaceName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func joinSection(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("초대 코드")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(theme.textSecondary)
                TextField("6자리 코드 입력", text: $inviteCode)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.characters)
                    .padding()
                    .background(theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: inviteCode) { _, newValue in
                        inviteCode = String(newValue.prefix(6)).uppercased()
                    }
            }

            Button(action: { Task { await joinWorkspace() } }) {
                HStack {
                    if isLoading { ProgressView().tint(.white) }
                    Text("참여하기")
                        .font(.system(.body, design: .rounded).bold())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(colors: theme.gradient, startPoint: .leading, endPoint: .trailing))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(inviteCode.count != 6 || isLoading)
            .opacity(inviteCode.count != 6 ? 0.5 : 1)
        }
        .padding(.horizontal, 24)
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
            await DataManager.shared.fetchAll()
            onComplete()
        } else {
            errorMessage = WorkspaceManager.shared.errorMessage ?? "참여에 실패했습니다"
            showError = true
        }
    }
}
