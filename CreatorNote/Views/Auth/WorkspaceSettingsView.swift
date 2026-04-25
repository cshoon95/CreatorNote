import SwiftUI

struct WorkspaceSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var generatedCode: String?
    @State private var isGenerating = false
    @State private var showLeaveAlert = false
    @State private var showDeleteAlert = false
    @State private var copied = false
    @State private var memberToRemove: Profile?
    @State private var showRemoveAlert = false

    private var isOwner: Bool {
        AuthManager.shared.currentUser?.id == WorkspaceManager.shared.currentWorkspace?.ownerId
    }

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
                            Text(isOwner ? "방장" : "멤버")
                                .font(.caption)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
            }

            // Members
            Section("멤버 (\(WorkspaceManager.shared.members.count))") {
                ForEach(WorkspaceManager.shared.members) { member in
                    let memberIsOwner = member.id == WorkspaceManager.shared.currentWorkspace?.ownerId
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
                        if memberIsOwner {
                            Text("방장")
                                .font(.caption.bold())
                                .foregroundStyle(theme.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(theme.primary.opacity(0.1))
                                .clipShape(Capsule())
                        } else if isOwner {
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

            // Pending Members (owner only)
            if !WorkspaceManager.shared.pendingMembers.isEmpty, isOwner {
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

            // Invite Code (owner only)
            if isOwner {
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
            }

            // Actions
            Section {
                if isOwner {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("워크스페이스 삭제")
                        }
                    }
                } else {
                    Button(role: .destructive, action: { showLeaveAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("워크스페이스 나가기")
                        }
                    }
                }
            } footer: {
                if isOwner {
                    Text("워크스페이스를 삭제하면 모든 데이터가 영구적으로 삭제됩니다.")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
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
            Text("이 워크스페이스에서 나가시겠습니까?")
        }
        .alert("워크스페이스 삭제", isPresented: $showDeleteAlert) {
            Button("삭제", role: .destructive) {
                Task { await WorkspaceManager.shared.deleteWorkspace() }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("워크스페이스와 모든 데이터가 영구적으로 삭제됩니다. 계속하시겠습니까?")
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
