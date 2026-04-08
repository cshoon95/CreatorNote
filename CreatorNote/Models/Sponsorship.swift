import Foundation

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
