import Foundation
import SwiftData

@Model
final class GeneralNote {
    var id: UUID
    var title: String
    var attributedContent: Data?
    var plainContent: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        title: String = "",
        plainContent: String = "",
        tags: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.plainContent = plainContent
        self.tags = tags
        self.createdAt = .now
        self.updatedAt = .now
    }
}
