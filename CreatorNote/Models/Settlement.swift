import Foundation
import SwiftData

@Model
final class Settlement {
    var id: UUID
    var sponsorship: Sponsorship?
    var brandName: String
    var amount: Double
    var fee: Double
    var tax: Double
    var settlementDate: Date?
    var isPaid: Bool
    var memo: String
    var createdAt: Date

    var netAmount: Double {
        amount - fee - tax
    }

    init(
        brandName: String,
        amount: Double = 0,
        fee: Double = 0,
        tax: Double = 0,
        settlementDate: Date? = nil,
        isPaid: Bool = false,
        memo: String = ""
    ) {
        self.id = UUID()
        self.brandName = brandName
        self.amount = amount
        self.fee = fee
        self.tax = tax
        self.settlementDate = settlementDate
        self.isPaid = isPaid
        self.memo = memo
        self.createdAt = .now
    }
}
