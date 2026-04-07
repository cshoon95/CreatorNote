import Foundation

extension Double {
    private static let krwFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var krwFormatted: String {
        Self.krwFormatter.string(from: NSNumber(value: self)) ?? "₩0"
    }
}
