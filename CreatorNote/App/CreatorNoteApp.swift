import SwiftUI
import SwiftData

@main
struct CreatorNoteApp: App {
    @State private var themeManager = ThemeManager.shared

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
}
