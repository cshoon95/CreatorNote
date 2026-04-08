import SwiftUI

struct NotesTabView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedSegment = 0

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            VStack(spacing: 0) {
                Picker("노트 유형", selection: $selectedSegment) {
                    HStack(spacing: 4) {
                        Image(systemName: "video.fill")
                        Text("릴스 노트")
                    }.tag(0)
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                        Text("일반 메모")
                    }.tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedSegment == 0 {
                    ReelsNoteListView()
                } else {
                    GeneralNoteListView()
                }
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
