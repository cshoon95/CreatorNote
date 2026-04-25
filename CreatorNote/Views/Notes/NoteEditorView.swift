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
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var editorCoordinator = RichTextCoordinator()
    @State private var showTemplateSheet = false
    @State private var isNewNote = false

    private var initialTemplateContent: String?
    private var initialTemplateTitle: String?
    private var templatePreSelected: Bool = false

    init(reelsNote: ReelsNoteDTO? = nil) {
        self.mode = .reels(reelsNote)
    }

    init(reelsNote: ReelsNoteDTO? = nil, templateContent: String, templateTitle: String) {
        self.mode = .reels(reelsNote)
        self.initialTemplateContent = templateContent
        self.initialTemplateTitle = templateTitle
        self.templatePreSelected = true
    }

    init(generalNote: GeneralNoteDTO? = nil) {
        self.mode = .general(generalNote)
    }

    private var isReelsMode: Bool {
        if case .reels = mode { return true }
        return false
    }

    private var existingCreatedBy: UUID? {
        switch mode {
        case .reels(let note): return note?.createdBy
        case .general(let note): return note?.createdBy
        }
    }

    private var existingUpdatedBy: UUID? {
        switch mode {
        case .reels(let note): return note?.updatedBy
        case .general(let note): return note?.updatedBy
        }
    }

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Title field
                    TextField("제목을 입력하세요", text: $title)
                        .font(.title2.bold())
                        .foregroundStyle(theme.textPrimary)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 16)

                    // 등록자·수정자 표시
                    if existingCreatedBy != nil || existingUpdatedBy != nil {
                        HStack(spacing: 12) {
                            if let createdBy = existingCreatedBy {
                                HStack(spacing: 4) {
                                    Text("등록")
                                        .font(.caption2)
                                        .foregroundStyle(theme.textSecondary)
                                    MemberChip(userId: createdBy)
                                }
                            }
                            if let updatedBy = existingUpdatedBy {
                                HStack(spacing: 4) {
                                    Text("수정")
                                        .font(.caption2)
                                        .foregroundStyle(theme.textSecondary)
                                    MemberChip(userId: updatedBy)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                    }

                    if isReelsMode {
                        reelsControls(theme: theme)
                    }

                    Rectangle()
                        .fill(theme.divider)
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                    RichTextEditor(
                        attributedText: $attributedContent,
                        plainText: $plainContent,
                        accentColor: UIColor(theme.primary),
                        coordinator: editorCoordinator
                    )

                    Rectangle()
                        .fill(theme.divider)
                        .frame(height: 1)

                    FormattingToolbar(coordinator: editorCoordinator)
                        .safeAreaPadding(.bottom)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .background(theme.background)
            .navigationTitle(isReelsMode ? "릴스 노트" : "메모")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundStyle(theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Haptic.success()
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.85)
                        } else {
                            Text("저장")
                                .font(.body.bold())
                                .foregroundStyle(theme.primary)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadContent()
                if case .reels(let note) = mode, note == nil {
                    isNewNote = true
                    if templatePreSelected {
                        if let templateTitle = initialTemplateTitle, !templateTitle.isEmpty && title.isEmpty {
                            title = templateTitle
                        }
                        if let content = initialTemplateContent, !content.isEmpty {
                            plainContent = content
                            attributedContent = NSAttributedString(string: content)
                            editorCoordinator.replaceText(content)
                        }
                    } else {
                        showTemplateSheet = true
                    }
                }
            }
            .sheet(isPresented: $showTemplateSheet) {
                NoteTemplateSheet { content, titlePlaceholder in
                    if !titlePlaceholder.isEmpty && title.isEmpty {
                        title = titlePlaceholder
                    }
                    if !content.isEmpty {
                        plainContent = content
                        attributedContent = NSAttributedString(string: content)
                        editorCoordinator.replaceText(content)
                    }
                }
                .presentationDetents([.large])
            }
            .alert("오류", isPresented: $showError) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private func reelsControls(theme: AppTheme) -> some View {
        // Status chips
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ReelsNoteStatus.allCases, id: \.self) { s in
                    Button {
                        Haptic.selection()
                        withAnimation(.spring(duration: 0.3)) { status = s }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: s.icon)
                                .font(.system(size: 11))
                            Text(s.displayName)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(status == s ? .bold : .medium)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(status == s ? .white : theme.textSecondary)
                        .background(status == s ? theme.primary : theme.surfaceBackground)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(status == s ? Color.clear : theme.divider, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 18)

        // Tag row
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 3) {
                        Text("#\(tag)")
                            .font(.caption)
                            .foregroundStyle(theme.textSecondary)
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                tags.removeAll { $0 == tag }
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(theme.textSecondary.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                HStack(spacing: 3) {
                    Text("#")
                        .font(.caption)
                        .foregroundStyle(theme.textSecondary.opacity(0.5))
                    TextField("태그 추가", text: $tagInput)
                        .font(.caption)
                        .frame(width: 72)
                        .foregroundStyle(theme.textPrimary)
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
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
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

    private func loadAttributedContent(from base64String: String?) {
        guard let base64String,
              let data = Data(base64Encoded: base64String),
              let attr = try? NSAttributedString(data: data, options: [
                  .documentType: NSAttributedString.DocumentType.rtf
              ], documentAttributes: nil) else { return }
        attributedContent = attr
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        DataManager.shared.errorMessage = nil
        let rtfBase64: String? = {
            guard let data = try? attributedContent.data(
                from: NSRange(location: 0, length: attributedContent.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) else { return nil }
            return data.base64EncodedString()
        }()

        switch mode {
        case .reels(let existing):
            if var updated = existing {
                updated.title = title
                updated.plainContent = plainContent
                updated.attributedContent = rtfBase64
                updated.status = status.rawValue
                updated.tags = tags
                updated.updatedAt = .now
                updated.updatedBy = AuthManager.shared.currentUser?.id
                await DataManager.shared.updateReelsNote(updated)
            } else {
                _ = await DataManager.shared.createReelsNote(
                    title: title,
                    plainContent: plainContent,
                    attributedContent: rtfBase64,
                    status: status,
                    tags: tags
                )
            }
        case .general(let existing):
            if var updated = existing {
                updated.title = title
                updated.plainContent = plainContent
                updated.attributedContent = rtfBase64
                updated.updatedAt = .now
                updated.updatedBy = AuthManager.shared.currentUser?.id
                await DataManager.shared.updateGeneralNote(updated)
            } else {
                _ = await DataManager.shared.createGeneralNote(
                    title: title,
                    plainContent: plainContent,
                    attributedContent: rtfBase64
                )
            }
        }

        if let msg = DataManager.shared.errorMessage {
            errorMessage = msg
            showError = true
        } else {
            dismiss()
        }
    }
}
