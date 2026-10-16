//
//  HighlightedTextInput.swift
//  Calendr
//

import SwiftUI

struct EventTitleHighlight: Equatable {
    let range: NSRange
    let color: NSColor
}

struct HighlightedTextInput: View {

    @Binding var text: String
    @Binding var focus: Bool

    let placeholder: String
    let highlights: [EventTitleHighlight]
    let isInvalid: Bool = false
    var fontSize: CGFloat = 13
    var showsBorder: Bool = true

    var body: some View {
        HighlightedTextField(
            placeholder: placeholder,
            text: $text,
            highlights: highlights,
            fontSize: fontSize,
            focus: $focus
        )
        .padding(showsBorder ? 4 : 0)
        .overlay { showsBorder ? InputBorder(isInvalid: isInvalid) : nil }
    }
}

private struct HighlightedTextField: NSViewRepresentable {

    let placeholder: String
    @Binding var text: String
    let highlights: [EventTitleHighlight]
    let fontSize: CGFloat
    @Binding var focus: Bool

    private func makeTextField() -> NSTextField {

        let textField = FocusTextField(focus: $focus)

        textField.placeholderString = placeholder
        textField.font = .systemFont(ofSize: fontSize)
        textField.textColor = .textColor
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.allowsEditingTextAttributes = true
        textField.importsGraphics = false
        textField.focusRingType = .none
        textField.maximumNumberOfLines = 1
        textField.cell?.usesSingleLineMode = true
        textField.cell?.isScrollable = true
        textField.cell?.wraps = false
        textField.cell?.lineBreakMode = .byClipping

        return textField
    }

    func makeCoordinator() -> Coordinator {

        let textField = makeTextField()

        let coordinator = Coordinator($text, textField)

        textField.delegate = coordinator

        return coordinator
    }

    func makeNSView(context: Context) -> NSTextField {

        context.coordinator.textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {

        applyHighlights(highlights, from: text, fontSize: fontSize, to: textField)

        if focus, !textField.hasFocus {
            DispatchQueue.main.async {
                textField.focus()
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {

        @Binding private var text: String

        let textField: NSTextField

        init(_ text: Binding<String>, _ textField: NSTextField) {
            self._text = text
            self.textField = textField
        }

        func controlTextDidChange(_: Notification) {
            self.text = textField.stringValue
        }
    }
}

private func applyHighlights(
    _ highlights: [EventTitleHighlight],
    from text: String,
    fontSize: CGFloat,
    to textField: NSTextField
) {
    let fullRange = text.nsRange

    let attributedString = NSMutableAttributedString(
        string: text,
        attributes: [
            .font: NSFont.systemFont(ofSize: fontSize),
            .foregroundColor: NSColor.textColor,
        ]
    )

    for highlight in highlights {
        guard let range = highlight.range.intersection(fullRange) else { continue }
        attributedString.addAttributes([
            .font: NSFont.systemFont(ofSize: fontSize, weight: .semibold),
            .foregroundColor: highlight.color,
        ], range: range)
    }

    if let textStorage = textField.editor?.textStorage {
        attributedString.enumerateAttributes(in: fullRange) { attributes, range, _ in
            textStorage.setAttributes(attributes, range: range)
        }
    } else {
        textField.attributedStringValue = attributedString
    }
}

private extension NSTextField {

    var editor: NSTextView? {
        currentEditor() as? NSTextView
    }
}
