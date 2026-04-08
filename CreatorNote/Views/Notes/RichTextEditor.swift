import SwiftUI
import UIKit

@MainActor
@Observable
final class RichTextCoordinator {
    weak var textView: UITextView?

    func toggleBold() { toggleTrait(.traitBold) }
    func toggleItalic() { toggleTrait(.traitItalic) }

    func toggleUnderline() {
        guard let textView, textView.selectedRange.length > 0 else { return }
        let range = textView.selectedRange
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        let existing = mutable.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
        mutable.addAttribute(.underlineStyle, value: existing == 0 ? NSUnderlineStyle.single.rawValue : 0, range: range)
        textView.attributedText = mutable
        textView.selectedRange = range
    }

    func toggleStrikethrough() {
        guard let textView, textView.selectedRange.length > 0 else { return }
        let range = textView.selectedRange
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        let existing = mutable.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
        mutable.addAttribute(.strikethroughStyle, value: existing == 0 ? NSUnderlineStyle.single.rawValue : 0, range: range)
        textView.attributedText = mutable
        textView.selectedRange = range
    }

    func cycleHeading() {
        guard let textView, textView.selectedRange.length > 0 else { return }
        let range = textView.selectedRange
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        let currentFont = mutable.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 16)

        let newSize: CGFloat
        switch currentFont.pointSize {
        case 28...: newSize = 22
        case 22...: newSize = 18
        case 18...: newSize = 16
        default: newSize = 28
        }

        mutable.addAttribute(.font, value: UIFont.systemFont(ofSize: newSize, weight: newSize > 16 ? .bold : .regular), range: range)
        textView.attributedText = mutable
        textView.selectedRange = range
    }

    func toggleBullet() {
        guard let textView else { return }
        let text = textView.text ?? ""
        let range = textView.selectedRange
        let nsText = text as NSString
        let lineRange = nsText.lineRange(for: range)
        let lineText = nsText.substring(with: lineRange)

        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        let cursorOffset: Int
        if lineText.hasPrefix("• ") {
            mutable.replaceCharacters(in: lineRange, with: String(lineText.dropFirst(2)))
            cursorOffset = -2
        } else {
            mutable.replaceCharacters(in: lineRange, with: "• " + lineText)
            cursorOffset = 2
        }
        textView.attributedText = mutable
        textView.selectedRange = NSRange(location: max(0, min(range.location + cursorOffset, mutable.length)), length: 0)
    }

    func dismissKeyboard() {
        textView?.resignFirstResponder()
    }

    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let textView, textView.selectedRange.length > 0 else { return }
        let range = textView.selectedRange
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        let currentFont = mutable.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 16)
        let descriptor = currentFont.fontDescriptor

        var newTraits = descriptor.symbolicTraits
        if descriptor.symbolicTraits.contains(trait) {
            newTraits.remove(trait)
        } else {
            newTraits.insert(trait)
        }

        if let newDescriptor = descriptor.withSymbolicTraits(newTraits) {
            mutable.addAttribute(.font, value: UIFont(descriptor: newDescriptor, size: currentFont.pointSize), range: range)
            textView.attributedText = mutable
            textView.selectedRange = range
        }
    }
}

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var plainText: String
    var accentColor: UIColor
    var coordinator: RichTextCoordinator

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = true
        textView.tintColor = accentColor

        if attributedText.length > 0 {
            textView.attributedText = attributedText
        }

        // Store reference for SwiftUI toolbar actions
        Task { @MainActor in
            coordinator.textView = textView
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText && !context.coordinator.isEditing {
            uiView.attributedText = attributedText
        }
    }

    func makeCoordinator() -> TextViewDelegate {
        TextViewDelegate(self)
    }

    class TextViewDelegate: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.plainText = textView.text
        }
    }
}

struct FormattingToolbar: View {
    @Environment(ThemeManager.self) private var themeManager
    let coordinator: RichTextCoordinator

    var body: some View {
        let theme = themeManager.theme
        HStack(spacing: 0) {
            Group {
                toolbarButton(icon: "bold") { coordinator.toggleBold() }
                toolbarButton(icon: "italic") { coordinator.toggleItalic() }
                toolbarButton(icon: "underline") { coordinator.toggleUnderline() }
                toolbarButton(icon: "strikethrough") { coordinator.toggleStrikethrough() }
            }

            Spacer()

            Group {
                toolbarButton(icon: "textformat.size") { coordinator.cycleHeading() }
                toolbarButton(icon: "list.bullet") { coordinator.toggleBullet() }
            }

            Spacer()

            Button("완료") {
                coordinator.dismissKeyboard()
            }
            .font(.subheadline.bold())
            .foregroundStyle(theme.primary)
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(theme.surfaceBackground)
    }

    @ViewBuilder
    private func toolbarButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptic.light()
            action()
        }) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 40, height: 36)
                .foregroundStyle(themeManager.theme.primary)
        }
    }
}
