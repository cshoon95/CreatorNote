import Foundation

struct SettlementDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var workspaceId: UUID
    var sponsorshipId: UUID?
    var brandName: String
    var amount: Double
    var fee: Double
    var tax: Double
    var settlementDate: Date?
    var isPaid: Bool
    var memo: String
    var createdBy: UUID?
    var updatedBy: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, amount, fee, tax, memo
        case workspaceId = "workspace_id"
        case sponsorshipId = "sponsorship_id"
        case brandName = "brand_name"
        case settlementDate = "settlement_date"
        case isPaid = "is_paid"
        case createdBy = "created_by"
        case updatedBy = "updated_by"
        case createdAt = "created_at"
    }

    var netAmount: Double {
        amount - fee - tax
    }
}
