import Foundation

struct SponsorshipDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var brandName: String
    var productName: String
    var details: String
    var amount: Double
    var startDate: Date
    var endDate: Date
    var status: String
    var isPinned: Bool
    var createdBy: UUID?
    var updatedBy: UUID?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, details, amount, status
        case workspaceId = "workspace_id"
        case brandName = "brand_name"
        case productName = "product_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case isPinned = "is_pinned"
        case createdBy = "created_by"
        case updatedBy = "updated_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0
    }

    var isExpired: Bool {
        endDate < .now
    }

    var isExpiringSoon: Bool {
        daysRemaining <= 3 && daysRemaining >= 0
    }

    var sponsorshipStatus: SponsorshipStatus {
        SponsorshipStatus(rawValue: status) ?? .preSubmit
    }
}
