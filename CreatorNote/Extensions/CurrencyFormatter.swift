import Foundation

extension Double {
    private static let decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    var krwFormatted: String {
        let number = Self.decimalFormatter.string(from: NSNumber(value: self)) ?? "0"
        return "\(number)원"
    }
}
