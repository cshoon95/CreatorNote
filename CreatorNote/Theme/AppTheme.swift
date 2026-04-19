import SwiftUI

enum AppThemeType: String, CaseIterable, Identifiable {
    case lavender = "라벤더"
    case rose = "로즈"
    case ocean = "오션"
    case mint = "민트"
    case sunset = "선셋"
    case midnight = "미드나잇"
    case pastel = "파스텔"
    case clean = "클린"

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
        case .pastel: return "cloud.fill"
        case .clean: return "square.stack.fill"
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
    let success: Color
    let warning: Color
    let danger: Color
    let divider: Color

    var isDark: Bool { type == .midnight }
    var colorScheme: ColorScheme? { isDark ? .dark : nil }

    static func theme(for type: AppThemeType) -> AppTheme {
        switch type {
        case .lavender:
            return AppTheme(
                type: .lavender,
                primary: Color(hex: "7C3AED"),
                secondary: Color(hex: "A78BFA"),
                accent: Color(hex: "EC4899"),
                background: Color(hex: "F5F3FF"),
                surfaceBackground: Color(hex: "EDE9FE"),
                cardBackground: .white,
                textPrimary: Color(hex: "1A1A2E"),
                textSecondary: Color(hex: "6B6B8D"),
                gradient: [Color(hex: "7C3AED"), Color(hex: "C4B5FD")],
                success: .green,
                warning: .orange,
                danger: Color(red: 1, green: 0.23, blue: 0.19),
                divider: Color.primary.opacity(0.12)
            )
        case .rose:
            return AppTheme(
                type: .rose,
                primary: Color(hex: "F43F5E"),
                secondary: Color(hex: "F48FB1"),
                accent: Color(hex: "FF6090"),
                background: Color(hex: "FFF1F2"),
                surfaceBackground: Color(hex: "FFE4E6"),
                cardBackground: .white,
                textPrimary: Color(hex: "2D1B2E"),
                textSecondary: Color(hex: "8D6B73"),
                gradient: [Color(hex: "F43F5E"), Color(hex: "FB7185")],
                success: .green,
                warning: .orange,
                danger: Color(red: 1, green: 0.23, blue: 0.19),
                divider: Color.primary.opacity(0.12)
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
                gradient: [Color(hex: "0288D1"), Color(hex: "4FC3F7")],
                success: .green,
                warning: .orange,
                danger: Color(red: 1, green: 0.23, blue: 0.19),
                divider: Color.primary.opacity(0.12)
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
                gradient: [Color(hex: "00BFA5"), Color(hex: "80CBC4")],
                success: .green,
                warning: .orange,
                danger: Color(red: 1, green: 0.23, blue: 0.19),
                divider: Color.primary.opacity(0.12)
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
                gradient: [Color(hex: "FF6D00"), Color(hex: "FFAB40")],
                success: .green,
                warning: .orange,
                danger: Color(red: 1, green: 0.23, blue: 0.19),
                divider: Color.primary.opacity(0.12)
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
                gradient: [Color(hex: "5C6BC0"), Color(hex: "7986CB")],
                success: Color(red: 0.2, green: 0.8, blue: 0.4),
                warning: Color(red: 1, green: 0.7, blue: 0.2),
                danger: Color(red: 1, green: 0.35, blue: 0.35),
                divider: Color.primary.opacity(0.12)
            )
        case .pastel:
            return AppTheme(
                type: .pastel,
                primary: Color(hex: "8B5CF6"),
                secondary: Color(hex: "EC4899"),
                accent: Color(hex: "06B6D4"),
                background: Color(hex: "F8F7FE"),
                surfaceBackground: Color(hex: "F0EEFF"),
                cardBackground: .white,
                textPrimary: Color(hex: "1E1B4B"),
                textSecondary: Color(hex: "8B83A3"),
                gradient: [Color(hex: "C4B5FD"), Color(hex: "F9A8D4")],
                success: Color(hex: "10B981"),
                warning: Color(hex: "F59E0B"),
                danger: Color(hex: "F43F5E"),
                divider: Color(hex: "EDE9FE")
            )
        case .clean:
            return AppTheme(
                type: .clean,
                primary: Color(hex: "0095F6"),
                secondary: Color(hex: "00376B"),
                accent: Color(hex: "FF3040"),
                background: Color(hex: "FFFFFF"),
                surfaceBackground: Color(hex: "FAFAFA"),
                cardBackground: Color(hex: "FFFFFF"),
                textPrimary: Color(hex: "262626"),
                textSecondary: Color(hex: "8E8E8E"),
                gradient: [Color(hex: "515BD4"), Color(hex: "DD2A7B"), Color(hex: "F58529")],
                success: Color(hex: "58C322"),
                warning: Color(hex: "FFBB00"),
                danger: Color(hex: "ED4956"),
                divider: Color(hex: "DBDBDB")
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
