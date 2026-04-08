import SwiftUI
import SwiftData

enum NoteEditorMode {
    case reels(ReelsNote?)
    case general(GeneralNote?)
}

struct NoteEditorView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
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

    init(reelsNote: ReelsNote? = nil) {
        self.mode = .reels(reelsNote)
    }

    init(generalNote: GeneralNote? = nil) {
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
            status = note.status
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
            if let note = existing {
                note.title = title
                note.plainContent = plainContent
                note.attributedContent = rtfData
                note.status = status
                note.tags = tags
                note.updatedAt = .now
            } else {
                let note = ReelsNote(title: title, plainContent: plainContent, status: status, tags: tags)
                note.attributedContent = rtfData
                modelContext.insert(note)
            }
        case .general(let existing):
            if let note = existing {
                note.title = title
                note.plainContent = plainContent
                note.attributedContent = rtfData
                note.updatedAt = .now
            } else {
                let note = GeneralNote(title: title, plainContent: plainContent)
                note.attributedContent = rtfData
                modelContext.insert(note)
            }
        }
        dismiss()
    }
}
