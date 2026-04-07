import Foundation
import SwiftData

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

@Model
final class ReelsNote {
    var id: UUID
    var title: String
    var attributedContent: Data?
    var plainContent: String
    var status: ReelsNoteStatus
    var sponsorship: Sponsorship?
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String = "",
        plainContent: String = "",
        status: ReelsNoteStatus = .drafting,
        tags: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.plainContent = plainContent
        self.status = status
        self.tags = tags
        self.createdAt = .now
        self.updatedAt = .now
    }
}
