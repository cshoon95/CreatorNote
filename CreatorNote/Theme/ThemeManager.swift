import SwiftUI

@MainActor
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var currentThemeType: AppThemeType {
        didSet {
            UserDefaults.standard.set(currentThemeType.rawValue, forKey: "selectedTheme")
        }
    }

    var theme: AppTheme {
        AppTheme.theme(for: currentThemeType)
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedTheme") ?? ""
        self.currentThemeType = AppThemeType(rawValue: saved) ?? .lavender
    }

    func setTheme(_ type: AppThemeType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentThemeType = type
        }
    }
}
