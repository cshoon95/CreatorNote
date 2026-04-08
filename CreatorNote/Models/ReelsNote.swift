import Foundation

enum ReelsNoteStatus: String, Codable, CaseIterable {
    case drafting = "작성중"
    case readyToUpload = "업로드 대기"
    case uploaded = "업로드 완료"

    var icon: String {
        switch self {
        case .drafting: return "pencil.circle.fill"
        case .readyToUpload: return "clock.fill"
        case .uploaded: return "checkmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .drafting: return "orange"
        case .readyToUpload: return "blue"
        case .uploaded: return "green"
        }
    }
}
