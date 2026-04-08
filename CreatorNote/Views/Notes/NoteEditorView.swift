import SwiftUI

enum NoteEditorMode {
    case reels(ReelsNoteDTO?)
    case general(GeneralNoteDTO?)
}

struct NoteEditorView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss

    let mode: NoteEditorMode

    @State private var title = ""
    @State private var attributedContent = NSAttributedString()
    @State private var plainContent = ""
    @State private var status: ReelsNoteStatus = .drafting
    @State private var tagInput = ""
    @State private var tags: [String] = []
    @State private var isSaving = false
    @State private var editorCoordinator = RichTextCoordinator()

    init(reelsNote: ReelsNoteDTO? = nil) {
        self.mode = .reels(reelsNote)
    }

    init(generalNote: GeneralNoteDTO? = nil) {
        self.mode = .general(generalNote)
    }

    private var isReelsMode: Bool {
        if case .reels = mode { return true }
        return false
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            VStack(spacing: 0) {
                TextField("제목을 입력하세요", text: $title)
                    .font(.title2.bold())
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if isReelsMode {
                    reelsControls(theme: theme)
                }

                Divider()
                    .padding(.horizontal, 16)

                RichTextEditor(
                    attributedText: $attributedContent,
                    plainText: $plainContent,
                    accentColor: UIColor(theme.primary),
                    coordinator: editorCoordinator
                )

                Divider()

                FormattingToolbar(coordinator: editorCoordinator)
                    .safeAreaPadding(.bottom)
            }
            .background(theme.background)
            .navigationTitle(isReelsMode ? "릴스 노트" : "메모")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        Haptic.success()
                        save()
                    }
                    .foregroundStyle(theme.primary)
                    .fontWeight(.bold)
                    .disabled(isSaving)
                }
            }
            .onAppear { loadContent() }
        }
    }

    @ViewBuilder
    private func reelsControls(theme: AppTheme) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ReelsNoteStatus.allCases, id: \.self) { s in
                    Button {
                        Haptic.selection()
                        withAnimation(.spring(duration: 0.3)) { status = s }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: s.icon)
                                .font(.caption2)
                            Text(s.rawValue)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(status == s ? theme.primary : theme.surfaceBackground)
                        .foregroundStyle(status == s ? .white : theme.textSecondary)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 8)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundStyle(theme.accent)
                        Button {
                            withAnimation { tags.removeAll { $0 == tag } }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.surfaceBackground)
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                }

                TextField("태그 추가", text: $tagInput)
                    .font(.caption)
                    .frame(width: 80)
                    .onSubmit {
                        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty && !tags.contains(trimmed) {
                            withAnimation(.spring(duration: 0.3)) {
                                tags.append(trimmed)
                            }
                        }
                        tagInput = ""
                    }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 4)
    }

    private func loadContent() {
        switch mode {
        case .reels(let note):
            guard let note else { return }
            title = note.title
            plainContent = note.plainContent
            status = note.reelsNoteStatus
            tags = note.tags
            loadAttributedContent(from: note.attributedContent)
        case .general(let note):
            guard let note else { return }
            title = note.title
            plainContent = note.plainContent
            loadAttributedContent(from: note.attributedContent)
        }
    }

    private func loadAttributedContent(from data: Data?) {
        guard let data,
              let attr = try? NSAttributedString(data: data, options: [
                  .documentType: NSAttributedString.DocumentType.rtf
              ], documentAttributes: nil) else { return }
        attributedContent = attr
    }

    private func save() {
        isSaving = true
        let rtfData = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        switch mode {
        case .reels(let existing):
            if var updated = existing {
                updated.title = title
                updated.plainContent = plainContent
                updated.attributedContent = rtfData
                updated.status = status.rawValue
                updated.tags = tags
                updated.updatedAt = .now
                Task { await DataManager.shared.updateReelsNote(updated) }
            } else {
                Task {
                    if let created = await DataManager.shared.createReelsNote(
                        title: title,
                        plainContent: plainContent,
                        status: status,
                        tags: tags
                    ) {
                        // attributedContent is stored separately if needed
                        var note = created
                        note.attributedContent = rtfData
                        await DataManager.shared.updateReelsNote(note)
                    }
                }
            }
        case .general(let existing):
            if var updated = existing {
                updated.title = title
                updated.plainContent = plainContent
                updated.attributedContent = rtfData
                updated.updatedAt = .now
                Task { await DataManager.shared.updateGeneralNote(updated) }
            } else {
                Task {
                    if let created = await DataManager.shared.createGeneralNote(
                        title: title,
                        plainContent: plainContent
                    ) {
                        var note = created
                        note.attributedContent = rtfData
                        await DataManager.shared.updateGeneralNote(note)
                    }
                }
            }
        }
        dismiss()
    }
}
