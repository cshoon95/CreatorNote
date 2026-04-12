import SwiftUI

struct NotesTabView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedSegment = 0

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            Group {
                if selectedSegment == 0 {
                    ReelsNoteListView()
                } else {
                    GeneralNoteListView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $selectedSegment) {
                        Text("릴스 노트").tag(0)
                        Text("일반 메모").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
        }
    }
}
