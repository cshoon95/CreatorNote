import SwiftUI

enum AppThemeType: String, CaseIterable, Identifiable {
    case lavender = "라벤더"
    case rose = "로즈"
    case ocean = "오션"
    case mint = "민트"
    case sunset = "선셋"
    case midnight = "미드나잇"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .lavender: return "sparkles"
        case .rose: return "heart.fill"
        case .ocean: return "water.waves"
        case .mint: return "leaf.fill"
        case .sunset: return "sun.horizon.fill"
        case .midnight: return "moon.stars.fill"
        }
    }
}

struct AppTheme {
    let type: AppThemeType
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let surfaceBackground: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let gradient: [Color]

    static func theme(for type: AppThemeType) -> AppTheme {
        switch type {
        case .lavender:
            return AppTheme(
                type: .lavender,
                primary: Color(hex: "7C5CFC"),
                secondary: Color(hex: "B39DDB"),
                accent: Color(hex: "E040FB"),
                background: Color(hex: "F8F6FF"),
                surfaceBackground: Color(hex: "F0ECFF"),
                cardBackground: .white,
                textPrimary: Color(hex: "1A1A2E"),
                textSecondary: Color(hex: "6B6B8D"),
                gradient: [Color(hex: "7C5CFC"), Color(hex: "B39DDB")]
            )
        case .rose:
            return AppTheme(
                type: .rose,
                primary: Color(hex: "E91E63"),
                secondary: Color(hex: "F48FB1"),
                accent: Color(hex: "FF6090"),
                background: Color(hex: "FFF5F8"),
                surfaceBackground: Color(hex: "FFE8EE"),
                cardBackground: .white,
                textPrimary: Color(hex: "2D1B2E"),
                textSecondary: Color(hex: "8D6B73"),
                gradient: [Color(hex: "E91E63"), Color(hex: "F48FB1")]
            )
        case .ocean:
            return AppTheme(
                type: .ocean,
                primary: Color(hex: "0288D1"),
                secondary: Color(hex: "4FC3F7"),
                accent: Color(hex: "00B8D4"),
                background: Color(hex: "F5FAFF"),
                surfaceBackground: Color(hex: "E3F2FD"),
                cardBackground: .white,
                textPrimary: Color(hex: "0D1B2A"),
                textSecondary: Color(hex: "546E7A"),
                gradient: [Color(hex: "0288D1"), Color(hex: "4FC3F7")]
            )
        case .mint:
            return AppTheme(
                type: .mint,
                primary: Color(hex: "00BFA5"),
                secondary: Color(hex: "80CBC4"),
                accent: Color(hex: "1DE9B6"),
                background: Color(hex: "F5FFFC"),
                surfaceBackground: Color(hex: "E0F2F1"),
                cardBackground: .white,
                textPrimary: Color(hex: "1A2E2B"),
                textSecondary: Color(hex: "5D7D77"),
                gradient: [Color(hex: "00BFA5"), Color(hex: "80CBC4")]
            )
        case .sunset:
            return AppTheme(
                type: .sunset,
                primary: Color(hex: "FF6D00"),
                secondary: Color(hex: "FFAB40"),
                accent: Color(hex: "FF3D00"),
                background: Color(hex: "FFFAF5"),
                surfaceBackground: Color(hex: "FFF3E0"),
                cardBackground: .white,
                textPrimary: Color(hex: "2E1A0D"),
                textSecondary: Color(hex: "8D7560"),
                gradient: [Color(hex: "FF6D00"), Color(hex: "FFAB40")]
            )
        case .midnight:
            return AppTheme(
                type: .midnight,
                primary: Color(hex: "5C6BC0"),
                secondary: Color(hex: "7986CB"),
                accent: Color(hex: "448AFF"),
                background: Color(hex: "121224"),
                surfaceBackground: Color(hex: "1A1A36"),
                cardBackground: Color(hex: "232346"),
                textPrimary: Color(hex: "E8E8F0"),
                textSecondary: Color(hex: "9999B3"),
                gradient: [Color(hex: "5C6BC0"), Color(hex: "7986CB")]
            )
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
