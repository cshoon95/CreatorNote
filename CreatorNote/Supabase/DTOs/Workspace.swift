import Foundation

struct Workspace: Codable, Identifiable, Sendable {
    let id: UUID
    var name: String
    var ownerId: UUID
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name
        case ownerId = "owner_id"
        case createdAt = "created_at"
    }
}

struct InviteCode: Codable, Identifiable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var code: String
    var expiresAt: Date
    var maxUses: Int
    var usedCount: Int
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, code
        case workspaceId = "workspace_id"
        case expiresAt = "expires_at"
        case maxUses = "max_uses"
        case usedCount = "used_count"
        case isActive = "is_active"
    }
}
