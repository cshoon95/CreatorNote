import Foundation
import SwiftData

@Model
final class Sponsorship {
    var id: UUID
    var brandName: String
    var productName: String
    var details: String
    var amount: Double
    var startDate: Date
    var endDate: Date
    var isSettled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        brandName: String,
        productName: String = "",
        details: String = "",
        amount: Double = 0,
        startDate: Date = .now,
        endDate: Date = .now.addingTimeInterval(86400 * 30),
        isSettled: Bool = false
    ) {
        self.id = UUID()
        self.brandName = brandName
        self.productName = productName
        self.details = details
        self.amount = amount
        self.startDate = startDate
        self.endDate = endDate
        self.isSettled = isSettled
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
