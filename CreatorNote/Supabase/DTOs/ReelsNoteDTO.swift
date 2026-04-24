import Foundation

struct ReelsNoteDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var title: String
    var attributedContent: String?
    var plainContent: String
    var status: String
    var sponsorshipId: UUID?
    var tags: [String]
    var isPinned: Bool
    var createdBy: UUID?
    var updatedBy: UUID?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, tags, status
        case workspaceId = "workspace_id"
        case attributedContent = "attributed_content"
        case plainContent = "plain_content"
        case sponsorshipId = "sponsorship_id"
        case isPinned = "is_pinned"
        case createdBy = "created_by"
        case updatedBy = "updated_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var reelsNoteStatus: ReelsNoteStatus {
        ReelsNoteStatus(rawValue: status) ?? .drafting
    }
}
