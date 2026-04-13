import Foundation

enum ReelsNoteStatus: String, Codable, CaseIterable {
    case drafting = "drafting"
    case readyToUpload = "readyToUpload"
    case uploaded = "uploaded"

    var displayName: String {
        switch self {
        case .drafting: return "작성중"
        case .readyToUpload: return "업로드 대기"
        case .uploaded: return "업로드 완료"
        }
    }

    var icon: String {
        switch self {
        case .drafting: return "pencil.circle.fill"
        case .readyToUpload: return "clock.fill"
        case .uploaded: return "checkmark.circle.fill"
        }
    }
}
