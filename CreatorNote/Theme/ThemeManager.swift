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

    var followSystem: Bool {
        didSet {
            UserDefaults.standard.set(followSystem, forKey: "followSystemTheme")
        }
    }

    var theme: AppTheme {
        AppTheme.theme(for: currentThemeType)
    }

    var resolvedColorScheme: ColorScheme? {
        if followSystem { return nil }
        return theme.colorScheme
    }

    private init() {
        self.currentThemeType = .clean
        self.followSystem = false
    }

    func setTheme(_ type: AppThemeType) {
        withAnimation(.easeInOut(duration: 0.3)) {
            followSystem = false
            currentThemeType = type
        }
    }

    func toggleFollowSystem() {
        withAnimation(.easeInOut(duration: 0.3)) {
            followSystem.toggle()
        }
    }
}
