import SwiftUI

struct GeneralNoteListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var showingEditor = false
    @State private var selectedNote: GeneralNoteDTO?
    @State private var searchText = ""

    private var notes: [GeneralNoteDTO] { DataManager.shared.generalNotes }

    private var filtered: [GeneralNoteDTO] {
        var result = notes
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.plainContent.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result.sorted { ($0.isPinned ? 0 : 1) < ($1.isPinned ? 0 : 1) }
    }

    var body: some View {
        let theme = themeManager.theme
        VStack(spacing: 0) {
            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: notes.isEmpty ? "doc.text" : "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(theme.primary.opacity(0.5))
                    Text(notes.isEmpty ? "메모가 없습니다" : "검색 결과가 없습니다")
                        .foregroundStyle(theme.textSecondary)
                    if notes.isEmpty {
                        Text("자유롭게 메모를 작성해보세요")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                Spacer()
            } else {
                List {
                    ForEach(filtered) { note in
                        Button {
                            selectedNote = note
                            showingEditor = true
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    if note.isPinned {
                                        Image(systemName: "pin.fill")
                                            .font(.caption2)
                                            .foregroundStyle(theme.primary)
                                    }
                                    Text(note.title.isEmpty ? "제목 없음" : note.title)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(theme.textPrimary)
                                }
                                if !note.plainContent.isEmpty {
                                    Text(note.plainContent.prefix(60))
                                        .font(.caption)
                                        .foregroundStyle(theme.textSecondary)
                                        .lineLimit(2)
                                }
                                Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(theme.cardBackground)
                        .swipeActions(edge: .leading) {
                            Button {
                                Task { await togglePin(note) }
                            } label: {
                                Label(note.isPinned ? "고정 해제" : "고정", systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill")
                            }
                            .tint(theme.primary)
                        }
                    }
                    .onDelete(perform: delete)
                }
                .scrollContentBackground(.hidden)
                .searchable(text: $searchText, prompt: "메모 검색")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                selectedNote = nil
                showingEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(colors: themeManager.theme.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(Circle())
                    .shadow(color: themeManager.theme.primary.opacity(0.3), radius: 8, y: 4)
            }
            .padding(20)
        }
        .sheet(isPresented: $showingEditor) {
            if let selectedNote {
                NoteEditorView(generalNote: selectedNote)
            } else {
                NoteEditorView(generalNote: nil as GeneralNoteDTO?)
            }
        }
    }

    private func togglePin(_ note: GeneralNoteDTO) async {
        var updated = note
        updated.isPinned.toggle()
        await DataManager.shared.updateGeneralNote(updated)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = filtered[index]
            Task { await DataManager.shared.deleteGeneralNote(id: item.id) }
        }
    }
}
