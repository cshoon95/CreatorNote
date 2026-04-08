import SwiftUI
import SwiftData

@main
struct CreatorNoteApp: App {
    @State private var themeManager = ThemeManager.shared

    init() {
        configureNavBarAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(themeManager)
        }
        .modelContainer(for: [
            Sponsorship.self,
            Settlement.self,
            ReelsNote.self,
            GeneralNote.self
        ])
    }

    private func configureNavBarAppearance() {
        let large = UINavigationBarAppearance()
        large.configureWithTransparentBackground()
        large.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold).rounded(),
            .foregroundColor: UIColor.label
        ]
        large.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
            .foregroundColor: UIColor.label
        ]

        let inline = UINavigationBarAppearance()
        inline.configureWithDefaultBackground()
        inline.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold).rounded(),
            .foregroundColor: UIColor.label
        ]

        UINavigationBar.appearance().standardAppearance = inline
        UINavigationBar.appearance().scrollEdgeAppearance = large
        UINavigationBar.appearance().compactAppearance = inline
        UINavigationBar.appearance().prefersLargeTitles = true
    }
}

extension UIFont {
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
