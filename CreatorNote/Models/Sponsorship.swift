import Foundation
import SwiftData

enum SponsorshipStatus: String, Codable, CaseIterable {
    case preSubmit = "제출 전"
    case underReview = "검수중"
    case submitted = "제출 완료"
    case pendingSettlement = "정산 대기"
    case completed = "완료"

    var icon: String {
        switch self {
        case .preSubmit: return "doc.badge.clock"
        case .underReview: return "eye.circle.fill"
        case .submitted: return "checkmark.circle.fill"
        case .pendingSettlement: return "wonsign.circle.fill"
        case .completed: return "star.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .preSubmit: return "gray"
        case .underReview: return "orange"
        case .submitted: return "blue"
        case .pendingSettlement: return "purple"
        case .completed: return "green"
        }
    }
}

@Model
final class Sponsorship {
    var id: UUID
    var brandName: String
    var productName: String
    var details: String
    var amount: Double
    var startDate: Date
    var endDate: Date
    var status: SponsorshipStatus
    var createdAt: Date
    var updatedAt: Date

    init(
        brandName: String,
        productName: String = "",
        details: String = "",
        amount: Double = 0,
        startDate: Date = .now,
        endDate: Date = .now.addingTimeInterval(86400 * 30),
        status: SponsorshipStatus = .preSubmit
    ) {
        self.id = UUID()
        self.brandName = brandName
        self.productName = productName
        self.details = details
        self.amount = amount
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.createdAt = .now
        self.updatedAt = .now
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
}
