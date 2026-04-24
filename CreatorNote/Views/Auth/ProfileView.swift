import SwiftUI

struct ProfileView: View {
    @Environment(ThemeManager.self) private var themeManager

    @State private var displayName = ""
    @State private var isLoading = false
    @State private var isEditing = false
    @State private var editingName = ""
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showDeleteSuccess = false

    var body: some View {
        let theme = themeManager.theme
        ScrollView {
            VStack(spacing: 20) {
                profileHeader(theme: theme)
                nicknameSection(theme: theme)
                Spacer().frame(height: 40)
                deleteAccountSection(theme: theme)
            }
            .padding()
        }
        .background(theme.background)
        .navigationTitle("프로필")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("계정 탈퇴", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("탈퇴하기", role: .destructive) {
                Task { await deleteAccount() }
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("계정을 삭제하면 모든 데이터가 영구적으로 삭제되며 복구할 수 없습니다. 정말 탈퇴하시겠습니까?")
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .alert("탈퇴 완료", isPresented: $showDeleteSuccess) {
            Button("확인") {
                AuthManager.shared.isAuthenticated = false
            }
        } message: {
            Text("계정이 성공적으로 삭제되었습니다.")
        }
        .task {
            await loadProfile()
        }
    }

    private func profileHeader(theme: AppTheme) -> some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.primary)
                    .frame(width: 80, height: 80)
                    .shadow(color: theme.primary.opacity(0.3), radius: 12, x: 0, y: 6)

                Text(String((displayName.isEmpty ? "사" : displayName).prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text(displayName.isEmpty ? "사용자" : displayName)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private func nicknameSection(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("닉네임")
                .font(.caption.bold())
                .foregroundStyle(theme.textSecondary)

            if isEditing {
                HStack(spacing: 10) {
                    TextField("닉네임을 입력하세요", text: $editingName)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(theme.surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        Task { await saveNickname() }
                    } label: {
                        if isSaving {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("저장")
                                .font(.subheadline.bold())
                                .foregroundStyle(editingName.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : theme.primary)
                        }
                    }
                    .disabled(editingName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)

                    Button {
                        isEditing = false
                    } label: {
                        Text("취소")
                            .font(.subheadline)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            } else {
                HStack {
                    Text(displayName.isEmpty ? "사용자" : displayName)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Button {
                        editingName = displayName
                        isEditing = true
                    } label: {
                        Text("변경")
                            .font(.subheadline.bold())
                            .foregroundStyle(theme.primary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
    }

    private func deleteAccountSection(theme: AppTheme) -> some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 8) {
                if isDeleting {
                    ProgressView()
                        .tint(theme.textSecondary)
                        .scaleEffect(0.8)
                }
                Text("계정 탈퇴")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundStyle(theme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .disabled(isDeleting)
    }

    // MARK: - Actions

    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        if let profile = AuthManager.shared.currentProfile {
            displayName = profile.displayName ?? ""
        }
    }

    private func saveNickname() async {
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSaving = true
        defer { isSaving = false }
        await AuthManager.shared.updateDisplayName(trimmed)
        if AuthManager.shared.errorMessage == nil {
            displayName = trimmed
            isEditing = false
            ToastManager.shared.show("닉네임이 변경되었습니다")
        } else {
            errorMessage = AuthManager.shared.errorMessage
            showError = true
        }
    }

    private func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }
        await AuthManager.shared.deleteAccountData()
        if AuthManager.shared.errorMessage == nil {
            showDeleteSuccess = true
        } else {
            errorMessage = AuthManager.shared.errorMessage
            showError = true
        }
    }
}
