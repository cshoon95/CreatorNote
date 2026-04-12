import SwiftUI

struct ReelsNoteListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var filterStatus: ReelsNoteStatus?
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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // 검색바
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.textSecondary)
                    TextField("노트 검색", text: $searchText)
                        .foregroundStyle(theme.textPrimary)
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }
                .padding(14)
                .background(theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(
                            label: "전체",
                            count: notes.count,
                            isSelected: filterStatus == nil,
                            theme: theme
                        ) {
                            filterStatus = nil
                        }
                        ForEach(ReelsNoteStatus.allCases, id: \.self) { status in
                            filterChip(
                                label: status.displayName,
                                count: notes.filter { $0.reelsNoteStatus == status }.count,
                                isSelected: filterStatus == status,
                                theme: theme
                            ) {
                                filterStatus = status
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

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
                                        showingEditor = true
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
                selectedNote = nil
                showingEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        LinearGradient(
                            colors: theme.gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: theme.primary.opacity(0.35), radius: 10, y: 5)
            }
            .padding(20)
        }
        .sheet(isPresented: $showingEditor) {
            NoteEditorView(reelsNote: selectedNote)
        }
    }

    private func filterChip(
        label: String,
        count: Int,
        isSelected: Bool,
        theme: AppTheme,
        action: @escaping () -> Void
    ) -> some View {
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
            .padding(.vertical, 7)
            .background(isSelected ? theme.primary : theme.surfaceBackground)
            .foregroundStyle(isSelected ? .white : theme.textSecondary)
            .clipShape(Capsule())
        }
    }

    private func noteCard(_ note: ReelsNoteDTO, theme: AppTheme) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor(note.reelsNoteStatus))
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
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(note.tags.prefix(5), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(theme.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.accent.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                HStack {
                    Text(note.updatedAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption2)
                        .foregroundStyle(theme.textSecondary.opacity(0.7))
                    if let name = authorName(for: note.createdBy) {
                        Text("· \(name)")
                            .font(.caption2)
                            .foregroundStyle(theme.textSecondary.opacity(0.7))
                    }
                    Spacer()
                    StatusBadge(status: note.reelsNoteStatus)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: theme.primary.opacity(0.07), radius: 8, x: 0, y: 3)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                Task { await togglePin(note) }
            } label: {
                Label(
                    note.isPinned ? "고정 해제" : "고정",
                    systemImage: note.isPinned ? "pin.slash.fill" : "pin.fill"
                )
            }
            .tint(theme.primary)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                Task { await DataManager.shared.deleteReelsNote(id: note.id) }
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

    private func authorName(for userId: UUID?) -> String? {
        guard let userId else { return nil }
        let currentUserId = AuthManager.shared.currentUser?.id
        if userId == currentUserId { return "나" }
        return WorkspaceManager.shared.members.first { $0.id == userId }?.displayName
    }

    private func statusColor(_ status: ReelsNoteStatus) -> Color {
        switch status {
        case .drafting: return .orange
        case .readyToUpload: return .blue
        case .uploaded: return .green
        }
    }

    private func togglePin(_ note: ReelsNoteDTO) async {
        var updated = note
        updated.isPinned.toggle()
        await DataManager.shared.updateReelsNote(updated)
    }
}
