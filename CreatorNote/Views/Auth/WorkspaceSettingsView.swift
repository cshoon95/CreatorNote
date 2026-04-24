import SwiftUI

struct WorkspaceSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var generatedCode: String?
    @State private var isGenerating = false
    @State private var showLeaveAlert = false
    @State private var copied = false
    @State private var inviteInput = ""
    @State private var isJoining = false
    @State private var joinResult: String?
    @State private var memberToRemove: Profile?
    @State private var showRemoveAlert = false

    var body: some View {
        let theme = themeManager.theme
        List {
            // Workspace Info
            Section {
                if let workspace = WorkspaceManager.shared.currentWorkspace {
                    HStack {
                        Image(systemName: "briefcase.circle.fill")
                            .font(.title2)
                            .foregroundStyle(theme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workspace.name)
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(theme.textPrimary)
                            Text("워크스페이스")
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }

            // Members
            Section("멤버 (\(WorkspaceManager.shared.members.count))") {
                ForEach(WorkspaceManager.shared.members) { member in
                    let isOwner = member.id == WorkspaceManager.shared.currentWorkspace?.ownerId
                    let iAmOwner = AuthManager.shared.currentUser?.id == WorkspaceManager.shared.currentWorkspace?.ownerId
                    HStack {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text(String((member.displayName ?? "?").prefix(1)))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                        Text(member.displayName ?? "알 수 없음")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        if isOwner {
                            Text("방장")
                                .font(.caption.bold())
                                .foregroundStyle(theme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.primary.opacity(0.1))
                                .clipShape(Capsule())
                        } else if iAmOwner {
                            Button(role: .destructive) {
                                memberToRemove = member
                                showRemoveAlert = true
                            } label: {
                                Text("추방")
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Pending Members
            if !WorkspaceManager.shared.pendingMembers.isEmpty,
               AuthManager.shared.currentUser?.id == WorkspaceManager.shared.currentWorkspace?.ownerId {
                Section("승인 대기 (\(WorkspaceManager.shared.pendingMembers.count))") {
                    ForEach(WorkspaceManager.shared.pendingMembers) { member in
                        HStack {
                            Circle()
                                .fill(Color.orange.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay {
                                    Text(String((member.displayName ?? "?").prefix(1)))
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.orange)
                                }
                            Text(member.displayName ?? "알 수 없음")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            Button {
                                Task { await WorkspaceManager.shared.approveMember(userId: member.id) }
                            } label: {
                                Text("승인")
                                    .font(.caption.bold())
                                    .foregroundStyle(.green)
                            }
                            Button {
                                Task { await WorkspaceManager.shared.rejectMember(userId: member.id) }
                            } label: {
                                Text("거절")
                                    .font(.caption.bold())
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            // Invite Code
            Section("초대") {
                if let code = generatedCode {
                    HStack {
                        Text(code)
                            .font(.system(.title2, design: .monospaced).bold())
                            .foregroundStyle(theme.primary)
                        Spacer()
                        Button(action: {
                            UIPasteboard.general.string = code
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                        }) {
                            Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundStyle(copied ? .green : theme.primary)
                        }
                    }
                    Text("7일 후 만료 / 최대 5회 사용")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                } else {
                    Button(action: {
                        Task {
                            isGenerating = true
                            generatedCode = await WorkspaceManager.shared.generateInviteCode()
                            isGenerating = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("초대 코드 생성")
                            Spacer()
                            if isGenerating {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isGenerating)
                }
            }

            // 초대코드 입력
            Section("초대코드로 참여") {
                HStack(spacing: 10) {
                    TextField("초대코드 입력", text: $inviteInput)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .foregroundStyle(theme.textPrimary)

                    Button {
                        let code = inviteInput.trimmingCharacters(in: .whitespaces)
                        guard !code.isEmpty else { return }
                        Task {
                            isJoining = true
                            let success = await WorkspaceManager.shared.joinWithCode(code)
                            joinResult = success ? "승인 요청을 보냈습니다" : (WorkspaceManager.shared.errorMessage ?? "유효하지 않은 코드입니다")
                            isJoining = false
                            if success { inviteInput = "" }
                        }
                    } label: {
                        if isJoining {
                            ProgressView().scaleEffect(0.8)
                        } else {
                            Text("참여")
                                .font(.subheadline.bold())
                                .foregroundStyle(inviteInput.isEmpty ? .gray : theme.primary)
                        }
                    }
                    .disabled(inviteInput.trimmingCharacters(in: .whitespaces).isEmpty || isJoining)
                }

                if let result = joinResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(result.contains("완료") ? .green : .red)
                }
            }

            // Leave
            Section {
                Button(role: .destructive, action: { showLeaveAlert = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("워크스페이스 나가기")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.background)
        .navigationTitle("워크스페이스")
        .navigationBarTitleDisplayMode(.inline)
        .alert("워크스페이스 나가기", isPresented: $showLeaveAlert) {
            Button("나가기", role: .destructive) {
                Task { await WorkspaceManager.shared.leaveWorkspace() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("정말로 이 워크스페이스를 나가시겠습니까?")
        }
        .alert("멤버 추방", isPresented: $showRemoveAlert) {
            Button("추방", role: .destructive) {
                if let member = memberToRemove {
                    Task { await WorkspaceManager.shared.removeMember(userId: member.id) }
                }
                memberToRemove = nil
            }
            Button("취소", role: .cancel) { memberToRemove = nil }
        } message: {
            Text("\(memberToRemove?.displayName ?? "이 멤버")를 워크스페이스에서 추방하시겠습니까?")
        }
        .task {
            await WorkspaceManager.shared.fetchMembers()
        }
    }
}
