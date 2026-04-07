import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var plainText: String
    var accentColor: UIColor

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.backgroundColor = .clear
        textView.allowsEditingTextAttributes = true
        textView.tintColor = accentColor

        // Add toolbar
        let toolbar = makeToolbar(textView: textView, coordinator: context.coordinator)
        textView.inputAccessoryView = toolbar

        if attributedText.length > 0 {
            textView.attributedText = attributedText
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if the text is different to avoid cursor jumps
        if uiView.attributedText != attributedText && !context.coordinator.isEditing {
            uiView.attributedText = attributedText
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func makeToolbar(textView: UITextView, coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.tintColor = accentColor

        let bold = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: coordinator, action: #selector(Coordinator.toggleBold))
        let italic = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: coordinator, action: #selector(Coordinator.toggleItalic))
        let underline = UIBarButtonItem(image: UIImage(systemName: "underline"), style: .plain, target: coordinator, action: #selector(Coordinator.toggleUnderline))
        let strikethrough = UIBarButtonItem(image: UIImage(systemName: "strikethrough"), style: .plain, target: coordinator, action: #selector(Coordinator.toggleStrikethrough))

        let spacer1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let heading = UIBarButtonItem(image: UIImage(systemName: "textformat.size"), style: .plain, target: coordinator, action: #selector(Coordinator.cycleHeading))
        let bullet = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: coordinator, action: #selector(Coordinator.toggleBullet))

        let spacer2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        let done = UIBarButtonItem(barButtonSystemItem: .done, target: coordinator, action: #selector(Coordinator.dismissKeyboard))

        toolbar.items = [bold, italic, underline, strikethrough, spacer1, heading, bullet, spacer2, done]
        return toolbar
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        var isEditing = false
        weak var textView: UITextView?

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing = true
            self.textView = textView
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing = false
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.plainText = textView.text
        }

        @objc func toggleBold() {
            toggleTrait(.traitBold)
        }

        @objc func toggleItalic() {
            toggleTrait(.traitItalic)
        }

        @objc func toggleUnderline() {
            guard let textView else { return }
            let range = textView.selectedRange
            guard range.length > 0 else { return }
            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
            let existing = mutable.attribute(.underlineStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
            let newValue = existing == 0 ? NSUnderlineStyle.single.rawValue : 0
            mutable.addAttribute(.underlineStyle, value: newValue, range: range)
            textView.attributedText = mutable
            textView.selectedRange = range
            parent.attributedText = mutable
            parent.plainText = textView.text
        }

        @objc func toggleStrikethrough() {
            guard let textView else { return }
            let range = textView.selectedRange
            guard range.length > 0 else { return }
            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
            let existing = mutable.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) as? Int ?? 0
            let newValue = existing == 0 ? NSUnderlineStyle.single.rawValue : 0
            mutable.addAttribute(.strikethroughStyle, value: newValue, range: range)
            textView.attributedText = mutable
            textView.selectedRange = range
            parent.attributedText = mutable
            parent.plainText = textView.text
        }

        @objc func cycleHeading() {
            guard let textView else { return }
            let range = textView.selectedRange
            guard range.length > 0 else { return }
            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
            let currentFont = mutable.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 16)
            let currentSize = currentFont.pointSize

            let newSize: CGFloat
            switch currentSize {
            case 28...: newSize = 22
            case 22...: newSize = 18
            case 18...: newSize = 16
            default: newSize = 28
            }

            let newFont = UIFont.systemFont(ofSize: newSize, weight: newSize > 16 ? .bold : .regular)
            mutable.addAttribute(.font, value: newFont, range: range)
            textView.attributedText = mutable
            textView.selectedRange = range
            parent.attributedText = mutable
            parent.plainText = textView.text
        }

        @objc func toggleBullet() {
            guard let textView else { return }
            let text = textView.text ?? ""
            let range = textView.selectedRange
            let nsText = text as NSString
            let lineRange = nsText.lineRange(for: range)
            let lineText = nsText.substring(with: lineRange)

            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
            let cursorOffset: Int
            if lineText.hasPrefix("• ") {
                let newLine = String(lineText.dropFirst(2))
                mutable.replaceCharacters(in: lineRange, with: newLine)
                cursorOffset = -2
            } else {
                let newLine = "• " + lineText
                mutable.replaceCharacters(in: lineRange, with: newLine)
                cursorOffset = 2
            }
            textView.attributedText = mutable
            let newLocation = max(0, min(range.location + cursorOffset, mutable.length))
            textView.selectedRange = NSRange(location: newLocation, length: 0)
            parent.attributedText = mutable
            parent.plainText = textView.text
        }

        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }

        private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
            guard let textView else { return }
            let range = textView.selectedRange
            guard range.length > 0 else { return }
            let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
            let currentFont = mutable.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: 16)
            let descriptor = currentFont.fontDescriptor
            let hasTrait = descriptor.symbolicTraits.contains(trait)

            var newTraits = descriptor.symbolicTraits
            if hasTrait {
                newTraits.remove(trait)
            } else {
                newTraits.insert(trait)
            }

            if let newDescriptor = descriptor.withSymbolicTraits(newTraits) {
                let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                mutable.addAttribute(.font, value: newFont, range: range)
                textView.attributedText = mutable
                textView.selectedRange = range
                parent.attributedText = mutable
                parent.plainText = textView.text
            }
        }
    }
}
