import SwiftUI

struct GeneralNoteListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var showingNewNote = false
    @State private var selectedNote: GeneralNoteDTO?
    @State private var searchText = ""
    @State private var noteToDelete: GeneralNoteDTO?

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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // 검색바
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.textSecondary)
                    TextField("메모 검색", text: $searchText)
                        .foregroundStyle(theme.textPrimary)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
                .padding(14)
                .background(theme.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                if filtered.isEmpty {
                    emptyState(theme: theme)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { note in
                                noteCard(note, theme: theme)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        Haptic.selection()
                                        selectedNote = note
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 96)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

            Button {
                showingNewNote = true
            } label: {
                Circle()
                    .fill(theme.primary)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
            }
            .buttonStyle(.plain)
            .padding(20)
        }
        .sheet(item: $selectedNote) { note in
            NoteEditorView(generalNote: note)
        }
        .sheet(isPresented: $showingNewNote) {
            NoteEditorView(generalNote: nil)
        }
        .alert("메모를 삭제할까요?", isPresented: Binding(
            get: { noteToDelete != nil },
            set: { if !$0 { noteToDelete = nil } }
        )) {
            Button("취소", role: .cancel) { noteToDelete = nil }
            Button("삭제", role: .destructive) {
                if let note = noteToDelete {
                    Task { await DataManager.shared.deleteGeneralNote(id: note.id) }
                    noteToDelete = nil
                }
            }
        } message: {
            Text("삭제된 메모는 복구할 수 없습니다")
        }
    }

    private func noteCard(_ note: GeneralNoteDTO, theme: AppTheme) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.primary)
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 6) {
                    if note.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(theme.primary)
                            .rotationEffect(.degrees(45))
                    }
                    Text(note.title.isEmpty ? "제목 없음" : note.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(theme.textPrimary)
                        .lineLimit(1)
                    Spacer()
                }

                if !note.plainContent.isEmpty {
                    Text(note.plainContent)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                if !note.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }

                HStack {
                    Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary.opacity(0.7))
                    MemberChip(userId: note.createdBy)
                    Spacer()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.divider, lineWidth: 0.5)
        )
        .contextMenu {
            Button {
                Task { await togglePin(note) }
            } label: {
                Label(
                    note.isPinned ? "고정 해제" : "고정",
                    systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill"
                )
            }
            Button(role: .destructive) {
                Haptic.warning()
                noteToDelete = note
            } label: {
                Label("삭제", systemImage: "trash.fill")
            }
        }
    }

    private func emptyState(theme: AppTheme) -> some View {
        EmptyStateView(
            icon: "note.text",
            title: notes.isEmpty ? "메모가 없습니다" : "검색 결과가 없습니다",
            subtitle: notes.isEmpty ? "자유롭게 메모를 작성해보세요" : "다른 검색어를 입력해보세요",
            color: theme.primary
        )
    }

    private func togglePin(_ note: GeneralNoteDTO) async {
        var updated = note
        updated.isPinned.toggle()
        await DataManager.shared.updateGeneralNote(updated)
    }
}
