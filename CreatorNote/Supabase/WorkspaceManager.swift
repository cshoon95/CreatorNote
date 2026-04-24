import Foundation
@preconcurrency import Supabase

@MainActor @Observable
final class WorkspaceManager {
    static let shared = WorkspaceManager()

    var currentWorkspace: Workspace?
    var workspaces: [Workspace] = []
    var members: [Profile] = []
    var pendingMembers: [Profile] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    private init() {}

    var hasWorkspace: Bool { currentWorkspace != nil }

    func fetchWorkspaces() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result: [Workspace] = try await supabase
                .from("workspaces")
                .select()
                .execute()
                .value
            workspaces = result
        } catch {
            errorMessage = "워크스페이스를 불러올 수 없습니다"
        }
    }

    func selectWorkspace(id: UUID) async {
        do {
            let workspace: Workspace = try await supabase
                .from("workspaces")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value
            currentWorkspace = workspace
            UserDefaults.standard.set(id.uuidString, forKey: "current_workspace_id")
            await fetchMembers()
        } catch {
            errorMessage = "워크스페이스 선택에 실패했습니다"
        }
    }

    func createWorkspace(name: String) async -> Bool {
        guard let userId = AuthManager.shared.currentUser?.id else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            let newWorkspace = WorkspaceInsert(name: name, ownerId: userId)
            let created: Workspace = try await supabase
                .from("workspaces")
                .insert(newWorkspace)
                .select()
                .single()
                .execute()
                .value

            let membership = WorkspaceMemberInsert(workspaceId: created.id, userId: userId, role: "owner")
            try await supabase.from("workspace_members").insert(membership).execute()

            currentWorkspace = created
            UserDefaults.standard.set(created.id.uuidString, forKey: "current_workspace_id")
            await fetchWorkspaces()
            return true
        } catch {
            errorMessage = "워크스페이스 생성에 실패했습니다: \(error.localizedDescription)"
            return false
        }
    }

    func generateInviteCode() async -> String? {
        guard let workspace = currentWorkspace,
              let userId = AuthManager.shared.currentUser?.id else { return nil }
        let code = String((0..<6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".randomElement() ?? Character("A") })
        do {
            let invite = InviteCodeInsert(
                workspaceId: workspace.id, code: code, createdBy: userId,
                expiresAt: Date().addingTimeInterval(7 * 24 * 3600), maxUses: 5
            )
            try await supabase.from("invite_codes").insert(invite).execute()
            return code
        } catch {
            errorMessage = "초대 코드 생성에 실패했습니다"
            return nil
        }
    }

    func joinWithCode(_ code: String) async -> Bool {
        guard let userId = AuthManager.shared.currentUser?.id else { return false }

        // 이미 워크스페이스에 속해있는지 확인
        if currentWorkspace != nil {
            errorMessage = "이미 워크스페이스에 참여중입니다. 기존 워크스페이스를 나간 후 다시 시도하세요."
            return false
        }

        isLoading = true
        defer { isLoading = false }
        do {
            // 초대코드로 워크스페이스 ID 조회
            struct InviteRow: Codable {
                let workspaceId: UUID
                enum CodingKeys: String, CodingKey {
                    case workspaceId = "workspace_id"
                }
            }
            let invites: [InviteRow] = try await supabase
                .from("invite_codes")
                .select("workspace_id")
                .eq("code", value: code)
                .gt("expires_at", value: ISO8601DateFormatter().string(from: Date()))
                .execute()
                .value

            guard let invite = invites.first else {
                errorMessage = "유효하지 않은 초대 코드입니다"
                return false
            }

            // pending 상태로 멤버 추가
            let membership = WorkspaceMemberInsert(workspaceId: invite.workspaceId, userId: userId, role: "member")
            try await supabase.from("workspace_members")
                .insert(membership)
                .execute()

            // status를 pending으로 설정
            try await supabase.from("workspace_members")
                .update(["status": "pending"])
                .eq("workspace_id", value: invite.workspaceId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            ToastManager.shared.show("참여 요청을 보냈습니다. 방장의 승인을 기다려주세요.", icon: "clock.fill")
            return true
        } catch {
            errorMessage = "참여 요청에 실패했습니다"
            return false
        }
    }

    func fetchMembers() async {
        guard let workspace = currentWorkspace else { return }
        do {
            struct MemberRow: Codable {
                let userId: UUID
                let role: String
                let status: String
                enum CodingKeys: String, CodingKey {
                    case userId = "user_id"
                    case role
                    case status
                }
            }
            let memberRows: [MemberRow] = try await supabase
                .from("workspace_members")
                .select("user_id, role, status")
                .eq("workspace_id", value: workspace.id.uuidString)
                .execute()
                .value

            let approvedIds = memberRows.filter { $0.status == "approved" }.map(\.userId)
            let pendingIds = memberRows.filter { $0.status == "pending" }.map(\.userId)

            if !approvedIds.isEmpty {
                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: approvedIds.map(\.uuidString))
                    .execute()
                    .value
                members = profiles
            } else {
                members = []
            }

            if !pendingIds.isEmpty {
                let profiles: [Profile] = try await supabase
                    .from("profiles")
                    .select()
                    .in("id", values: pendingIds.map(\.uuidString))
                    .execute()
                    .value
                pendingMembers = profiles
            } else {
                pendingMembers = []
            }
        } catch {
            members = []
            pendingMembers = []
        }
    }

    func approveMember(userId: UUID) async {
        guard let workspace = currentWorkspace,
              workspace.ownerId == AuthManager.shared.currentUser?.id else { return }
        do {
            try await supabase
                .from("workspace_members")
                .update(["status": "approved"])
                .eq("workspace_id", value: workspace.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            await fetchMembers()
            ToastManager.shared.show("멤버를 승인했습니다", icon: "person.fill.checkmark")
        } catch {
            errorMessage = "멤버 승인에 실패했습니다"
        }
    }

    func rejectMember(userId: UUID) async {
        guard let workspace = currentWorkspace,
              workspace.ownerId == AuthManager.shared.currentUser?.id else { return }
        do {
            try await supabase
                .from("workspace_members")
                .delete()
                .eq("workspace_id", value: workspace.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            await fetchMembers()
            ToastManager.shared.show("참여 요청을 거절했습니다", icon: "person.fill.xmark")
        } catch {
            errorMessage = "요청 거절에 실패했습니다"
        }
    }

    func removeMember(userId: UUID) async {
        guard let workspace = currentWorkspace,
              workspace.ownerId == AuthManager.shared.currentUser?.id else {
            errorMessage = "방장만 멤버를 추방할 수 있습니다"
            return
        }
        guard userId != workspace.ownerId else {
            errorMessage = "방장은 추방할 수 없습니다"
            return
        }
        do {
            try await supabase
                .from("workspace_members")
                .delete()
                .eq("workspace_id", value: workspace.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            await fetchMembers()
            ToastManager.shared.show("멤버가 추방되었습니다", icon: "person.fill.xmark")
        } catch {
            errorMessage = "멤버 추방에 실패했습니다"
        }
    }

    func leaveWorkspace() async {
        guard let workspace = currentWorkspace,
              let userId = AuthManager.shared.currentUser?.id else { return }
        do {
            try await supabase
                .from("workspace_members")
                .delete()
                .eq("workspace_id", value: workspace.id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            currentWorkspace = nil
            UserDefaults.standard.removeObject(forKey: "current_workspace_id")
            await fetchWorkspaces()
        } catch {
            errorMessage = "워크스페이스 나가기에 실패했습니다"
        }
    }
}

struct WorkspaceInsert: Codable {
    let name: String
    let ownerId: UUID
    enum CodingKeys: String, CodingKey {
        case name
        case ownerId = "owner_id"
    }
}

struct WorkspaceMemberInsert: Codable {
    let workspaceId: UUID
    let userId: UUID
    let role: String
    enum CodingKeys: String, CodingKey {
        case workspaceId = "workspace_id"
        case userId = "user_id"
        case role
    }
}

struct InviteCodeInsert: Codable {
    let workspaceId: UUID
    let code: String
    let createdBy: UUID
    let expiresAt: Date
    let maxUses: Int
    enum CodingKeys: String, CodingKey {
        case code
        case workspaceId = "workspace_id"
        case createdBy = "created_by"
        case expiresAt = "expires_at"
        case maxUses = "max_uses"
    }
}
