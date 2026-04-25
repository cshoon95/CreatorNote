import SwiftUI

struct ReelsNoteListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var filterStatus: ReelsNoteStatus?
    @State private var showingNewNote = false
    @State private var showingTemplateSheet = false
    @State private var selectedTemplate: NoteTemplate?
    @State private var selectedNote: ReelsNoteDTO?
    @State private var searchText = ""
    @State private var noteToDelete: ReelsNoteDTO?
    @State private var sortOrder: SortOrder = .latest

    enum SortOrder: String, CaseIterable {
        case latest = "최신순"
        case title = "제목순"
        case status = "상태순"
    }

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
        return result.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            switch sortOrder {
            case .latest: return lhs.updatedAt > rhs.updatedAt
            case .title: return lhs.title.localizedCompare(rhs.title) == .orderedAscending
            case .status: return lhs.status < rhs.status
            }
        }
    }

    var body: some View {
        let theme = themeManager.theme
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline)
                        .foregroundStyle(theme.textSecondary)
                    TextField("노트 검색", text: $searchText)
                        .font(.subheadline)
                        .foregroundStyle(theme.textPrimary)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.textSecondary.opacity(0.6))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(theme.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 8)

                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChipView(label: "전체", count: notes.count, isSelected: filterStatus == nil, theme: theme) {
                                filterStatus = nil
                            }
                            ForEach(ReelsNoteStatus.allCases, id: \.self) { status in
                                FilterChipView(label: status.displayName, count: notes.filter { $0.reelsNoteStatus == status }.count, isSelected: filterStatus == status, theme: theme) {
                                    filterStatus = status
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    Spacer()

                    Menu {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            Button {
                                withAnimation { sortOrder = order }
                            } label: {
                                HStack {
                                    Text(order.rawValue)
                                    if sortOrder == order {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption2)
                            Text(sortOrder.rawValue)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.vertical, 10)

                if filtered.isEmpty {
                    emptyState(theme: theme)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
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

            Button { showingTemplateSheet = true } label: {
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
            NoteEditorView(reelsNote: note)
        }
        .sheet(isPresented: $showingTemplateSheet) {
            NoteTemplateSheet { content, titlePlaceholder in
                selectedTemplate = NoteTemplate.allCases.first { $0.content == content } ?? .blank
            }
            .presentationDetents([.large])
        }
        .onChange(of: showingTemplateSheet) { _, isShowing in
            if !isShowing && selectedTemplate != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    showingNewNote = true
                }
            }
        }
        .fullScreenCover(isPresented: $showingNewNote) {
            if let template = selectedTemplate {
                NoteEditorView(reelsNote: nil, templateContent: template.content, templateTitle: template.titlePlaceholder)
            } else {
                NoteEditorView(reelsNote: nil)
            }
        }
        .alert("노트를 삭제할까요?", isPresented: Binding(
            get: { noteToDelete != nil },
            set: { if !$0 { noteToDelete = nil } }
        )) {
            Button("취소", role: .cancel) { noteToDelete = nil }
            Button("삭제", role: .destructive) {
                if let note = noteToDelete {
                    Task { await DataManager.shared.deleteReelsNote(id: note.id) }
                    noteToDelete = nil
                }
            }
        } message: {
            Text("삭제된 노트는 복구할 수 없습니다")
        }
    }

    private func noteCard(_ note: ReelsNoteDTO, theme: AppTheme) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 4)
                .fill(note.reelsNoteStatus.color)
                .frame(width: 3)
                .padding(.vertical, 6)

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

                HStack(spacing: 6) {
                    Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary.opacity(0.7))
                    MemberChip(userId: note.createdBy)
                    Spacer()
                    StatusBadge(status: note.reelsNoteStatus)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
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
            icon: "video.circle.fill",
            title: notes.isEmpty ? "릴스 노트가 없습니다" : "검색 결과가 없습니다",
            subtitle: notes.isEmpty ? "대본, 캡션 등을 작성해보세요" : "다른 검색어를 입력해보세요",
            color: theme.primary
        )
    }

    private func togglePin(_ note: ReelsNoteDTO) async {
        var updated = note
        updated.isPinned.toggle()
        await DataManager.shared.updateReelsNote(updated)
    }
}
