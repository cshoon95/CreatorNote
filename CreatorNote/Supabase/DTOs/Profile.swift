import Foundation

struct Profile: Codable, Identifiable, Sendable {
    let id: UUID
    var displayName: String?
    var avatarUrl: String?
    var provider: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case provider
        case createdAt = "created_at"
    }
}
