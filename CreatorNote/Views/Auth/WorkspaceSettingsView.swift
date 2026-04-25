import SwiftUI

struct WorkspaceSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @State private var generatedCode: String?
    @State private var isGenerating = false
    @State private var showLeaveAlert = false
    @State private var showDeleteAlert = false
    @State private var copied = false
    @State private var memberToRemove: Profile?
    @State private var showRemoveAlert = false
    @State private var memberToApprove: Profile?
    @State private var showApproveAlert = false
    @State private var memberToReject: Profile?
    @State private var showRejectAlert = false

    private var isOwner: Bool {
        AuthManager.shared.currentUser?.id == WorkspaceManager.shared.currentWorkspace?.ownerId
    }

    var body: some View {
        let theme = themeManager.theme

        if WorkspaceManager.shared.isPendingApproval {
            pendingView(theme: theme)
        } else if !WorkspaceManager.shared.hasWorkspace {
            noWorkspaceView(theme: theme)
        } else {
            workspaceDetailView(theme: theme)
        }
    }

    @State private var showCancelPendingAlert = false
    @State private var isCheckingStatus = false

    private func pendingView(theme: AppTheme) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "clock.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundStyle(theme.primary)
                }

                VStack(spacing: 8) {
                    Text("승인 대기중")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(theme.textPrimary)

                    if let name = WorkspaceManager.shared.pendingWorkspace?.name {
                        HStack(spacing: 6) {
                            Image(systemName: "briefcase.fill")
                                .font(.caption)
                            Text(name)
                                .font(.system(.subheadline, design: .rounded).bold())
                        }
                        .foregroundStyle(theme.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(theme.primary.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Text("방장이 참여 요청을 승인하면\n자동으로 입장됩니다")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                VStack(spacing: 12) {
                    Button {
                        Task {
                            isCheckingStatus = true
                            await WorkspaceManager.shared.checkApprovalStatus()
                            isCheckingStatus = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isCheckingStatus {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline.bold())
                            }
                            Text("승인 상태 확인")
                                .font(.system(.body, design: .rounded).bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(.white)
                        .background(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isCheckingStatus)

                    Button {
                        showCancelPendingAlert = true
                    } label: {
                        Text("참여 요청 취소")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .background(theme.background)
        .navigationTitle("워크스페이스")
        .navigationBarTitleDisplayMode(.inline)
        .alert("참여 요청 취소", isPresented: $showCancelPendingAlert) {
            Button("취소하기", role: .destructive) {
                Task { await WorkspaceManager.shared.cancelPendingRequest() }
            }
            Button("계속 대기", role: .cancel) {}
        } message: {
            Text("참여 요청을 취소하면 처음부터 다시 시도해야 합니다.")
        }
    }

    private func noWorkspaceView(theme: AppTheme) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "person.2.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(theme.primary.opacity(0.6))

                VStack(spacing: 8) {
                    Text("워크스페이스가 없습니다")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(theme.textPrimary)
                    Text("워크스페이스를 만들거나 초대 코드로 참여하세요")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    NavigationLink {
                        WorkspaceSetupView {
                            dismiss()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("워크스페이스 설정하기")
                                .font(.system(.body, design: .rounded).bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.white)
                        .background(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .background(theme.background)
        .navigationTitle("워크스페이스")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func workspaceDetailView(theme: AppTheme) -> some View {
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
                            .fill(ProfileColor.color(for: member.id))
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
                        Button {
                            memberToApprove = member
                            showApproveAlert = true
                        } label: {
                            HStack {
                                Circle()
                                    .fill(ProfileColor.color(for: member.id))
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
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
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
        .alert("참여 요청", isPresented: $showApproveAlert) {
            Button("승인") {
                if let member = memberToApprove {
                    Task { await WorkspaceManager.shared.approveMember(userId: member.id) }
                }
                memberToApprove = nil
            }
            Button("거절", role: .destructive) {
                if let member = memberToApprove {
                    Task { await WorkspaceManager.shared.rejectMember(userId: member.id) }
                }
                memberToApprove = nil
            }
            Button("취소", role: .cancel) { memberToApprove = nil }
        } message: {
            Text("\(memberToApprove?.displayName ?? "알 수 없음")님이 워크스페이스에 참여하고 싶어합니다.")
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
