import SwiftUI

struct NotesTabView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedSegment = 0

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            VStack(spacing: 0) {
                TossPillTabBar(
                    tabs: ["릴스 노트", "일반 메모"],
                    selectedIndex: $selectedSegment,
                    theme: theme
                )
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    if selectedSegment == 0 {
                        ReelsNoteListView()
                    } else {
                        GeneralNoteListView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct TossPillTabBar: View {
    let tabs: [String]
    @Binding var selectedIndex: Int
    let theme: AppTheme

    var body: some View {
        HStack(spacing: 24) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, label in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedIndex = index
                    }
                    Haptic.selection()
                } label: {
                    VStack(spacing: 6) {
                        Text(label)
                            .font(.subheadline)
                            .fontWeight(selectedIndex == index ? .bold : .regular)
                            .foregroundStyle(selectedIndex == index ? theme.textPrimary : theme.textSecondary)
                        Rectangle()
                            .fill(selectedIndex == index ? theme.primary : .clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
