import SwiftUI

struct ReelsNoteListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var filterStatus: ReelsNoteStatus? = nil
    @State private var showingEditor = false
    @State private var selectedNote: ReelsNoteDTO?
    @State private var searchText = ""

    private var notes: [ReelsNoteDTO] { DataManager.shared.reelsNotes }

    private var filtered: [ReelsNoteDTO] {
        var result = notes
        if let filterStatus {
            result = result.filter { $0.reelsNoteStatus == filterStatus }
        }
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
            // Status filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "전체", count: notes.count, isSelected: filterStatus == nil, theme: theme) {
                        filterStatus = nil
                    }
                    ForEach(ReelsNoteStatus.allCases, id: \.self) { status in
                        filterChip(label: status.rawValue, count: notes.filter { $0.reelsNoteStatus == status }.count, isSelected: filterStatus == status, theme: theme) {
                            filterStatus = status
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            if filtered.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "video.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(theme.primary.opacity(0.5))
                    Text("릴스 노트가 없습니다")
                        .foregroundStyle(theme.textSecondary)
                    Text("대본, 캡션 등을 작성해보세요")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(filtered) { note in
                        Button {
                            selectedNote = note
                            showingEditor = true
                        } label: {
                            noteRow(note, theme: theme)
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
                .searchable(text: $searchText, prompt: "릴스 노트 검색")
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
            NoteEditorView(reelsNote: selectedNote)
        }
    }

    @ViewBuilder
    private func filterChip(label: String, count: Int, isSelected: Bool, theme: AppTheme, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptic.selection()
            action()
        }) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption.bold())
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isSelected ? .white.opacity(0.3) : theme.primary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isSelected ? theme.primary : theme.surfaceBackground)
            .foregroundStyle(isSelected ? .white : theme.textSecondary)
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func noteRow(_ note: ReelsNoteDTO, theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if note.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(theme.primary)
                }
                Text(note.title.isEmpty ? "제목 없음" : note.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                StatusBadge(status: note.reelsNoteStatus)
            }
            if !note.plainContent.isEmpty {
                Text(note.plainContent.prefix(80))
                    .font(.caption)
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(2)
            }
            HStack {
                Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(theme.textSecondary.opacity(0.7))
                if !note.tags.isEmpty {
                    ForEach(note.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .foregroundStyle(theme.accent)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func togglePin(_ note: ReelsNoteDTO) async {
        var updated = note
        updated.isPinned.toggle()
        await DataManager.shared.updateReelsNote(updated)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = filtered[index]
            Task { await DataManager.shared.deleteReelsNote(id: item.id) }
        }
    }
}
