import Foundation

struct GeneralNoteDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var title: String
    var attributedContent: Data?
    var plainContent: String
    var tags: [String]
    var isPinned: Bool
    var createdBy: UUID?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, tags
        case workspaceId = "workspace_id"
        case attributedContent = "attributed_content"
        case plainContent = "plain_content"
        case isPinned = "is_pinned"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
