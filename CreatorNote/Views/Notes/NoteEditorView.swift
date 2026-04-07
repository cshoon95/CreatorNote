import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var reelsNote: ReelsNote?
    var generalNote: GeneralNote?
    var isReelsNote: Bool { generalNote == nil }

    @State private var title = ""
    @State private var attributedContent = NSAttributedString()
    @State private var plainContent = ""
    @State private var status: ReelsNoteStatus = .drafting
    @State private var tagInput = ""
    @State private var tags: [String] = []

    var body: some View {
        let theme = themeManager.theme
        NavigationStack {
            VStack(spacing: 0) {
                // Title field
                TextField("제목을 입력하세요", text: $title)
                    .font(.title2.bold())
                    .foregroundStyle(theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                if isReelsNote {
                    // Status selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ReelsNoteStatus.allCases, id: \.self) { s in
                                Button {
                                    withAnimation { status = s }
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

                    // Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text("#\(tag)")
                                        .font(.caption)
                                        .foregroundStyle(theme.accent)
                                    Button {
                                        tags.removeAll { $0 == tag }
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
                            }

                            TextField("태그 추가", text: $tagInput)
                                .font(.caption)
                                .frame(width: 80)
                                .onSubmit {
                                    let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
                                    if !trimmed.isEmpty && !tags.contains(trimmed) {
                                        tags.append(trimmed)
                                    }
                                    tagInput = ""
                                }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 4)
                }

                Divider()
                    .padding(.horizontal, 16)

                // Rich text editor
                RichTextEditor(
                    attributedText: $attributedContent,
                    plainText: $plainContent,
                    accentColor: UIColor(theme.primary)
                )
            }
            .background(theme.background)
            .navigationTitle(isReelsNote ? "릴스 노트" : "메모")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .foregroundStyle(theme.primary)
                        .fontWeight(.bold)
                }
            }
            .onAppear { loadContent() }
        }
    }

    private func loadContent() {
        if let note = reelsNote {
            title = note.title
            plainContent = note.plainContent
            status = note.status
            tags = note.tags
            if let data = note.attributedContent,
               let attr = try? NSAttributedString(data: data, options: [
                   .documentType: NSAttributedString.DocumentType.rtf
               ], documentAttributes: nil) {
                attributedContent = attr
            }
        } else if let note = generalNote {
            title = note.title
            plainContent = note.plainContent
            if let data = note.attributedContent,
               let attr = try? NSAttributedString(data: data, options: [
                   .documentType: NSAttributedString.DocumentType.rtf
               ], documentAttributes: nil) {
                attributedContent = attr
            }
        }
    }

    private func save() {
        let rtfData = try? attributedContent.data(
            from: NSRange(location: 0, length: attributedContent.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        if let note = reelsNote {
            note.title = title
            note.plainContent = plainContent
            note.attributedContent = rtfData
            note.status = status
            note.tags = tags
            note.updatedAt = .now
        } else if let note = generalNote {
            note.title = title
            note.plainContent = plainContent
            note.attributedContent = rtfData
            note.updatedAt = .now
        } else if isReelsNote {
            let note = ReelsNote(title: title, plainContent: plainContent, status: status, tags: tags)
            note.attributedContent = rtfData
            modelContext.insert(note)
        } else {
            let note = GeneralNote(title: title, plainContent: plainContent)
            note.attributedContent = rtfData
            modelContext.insert(note)
        }
        dismiss()
    }
}
