import SwiftUI

struct ReelsNoteListView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var filterStatus: ReelsNoteStatus?
    @State private var showingEditor = false
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
                // 검색바
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
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(theme.surfaceBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // 필터 칩 + 정렬
                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
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
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption2)
                            Text(sortOrder.rawValue)
                                .font(.caption)
                        }
                        .foregroundStyle(theme.textSecondary)
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

            // FAB
            Button {
                selectedNote = nil
                showingEditor = true
            } label: {
                Image(systemName: "plus")
                    .font(.title3)
                    .foregroundStyle(theme.primary)
                    .frame(width: 52, height: 52)
                    .background(theme.cardBackground)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.08), radius: 8, y: 2)
                    .overlay(Circle().stroke(theme.divider, lineWidth: 0.5))
            }
            .padding(20)
        }
        .sheet(isPresented: $showingEditor) {
            NoteEditorView(reelsNote: selectedNote)
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

    // MARK: - View Builders

    private func filterChip(
        label: String,
        count: Int,
        isSelected: Bool,
        theme: AppTheme,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            Haptic.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                action()
            }
        }) {
            HStack(spacing: 3) {
                Text(label)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                }
            }
            .foregroundStyle(isSelected ? theme.primary : theme.textSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func noteCard(_ note: ReelsNoteDTO, theme: AppTheme) -> some View {
        HStack(spacing: 0) {
            // 왼쪽 상태 색상 바
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor(note.reelsNoteStatus))
                .frame(width: 4)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 8) {
                // 제목 행
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

                // 본문 미리보기
                if !note.plainContent.isEmpty {
                    Text(note.plainContent)
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                // 태그
                if !note.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(note.tags.prefix(3), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                }

                // 하단 메타 행
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
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
            icon: "video.circle.fill",
            title: notes.isEmpty ? "릴스 노트가 없습니다" : "검색 결과가 없습니다",
            subtitle: notes.isEmpty ? "대본, 캡션 등을 작성해보세요" : "다른 검색어를 입력해보세요",
            color: theme.primary
        )
    }

    // MARK: - Helpers

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
