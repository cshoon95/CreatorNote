import Foundation

enum SponsorshipStatus: String, Codable, CaseIterable {
    case preSubmit = "preSubmit"
    case underReview = "underReview"
    case submitted = "submitted"
    case pendingSettlement = "pendingSettlement"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .preSubmit: return "제출 전"
        case .underReview: return "검수중"
        case .submitted: return "제출 완료"
        case .pendingSettlement: return "정산 대기"
        case .completed: return "완료"
        }
    }

    var icon: String {
        switch self {
        case .preSubmit: return "doc.badge.clock"
        case .underReview: return "eye.circle.fill"
        case .submitted: return "checkmark.circle.fill"
        case .pendingSettlement: return "wonsign.circle.fill"
        case .completed: return "star.circle.fill"
        }
    }
}
