//
//  HighlightedTextInput.swift
//  Calendr
//

import AppKit
import SwiftUI

struct EventTitleHighlight: Equatable {
    let range: NSRange
    let color: NSColor
}

struct HighlightedTextInput: View {

    let placeholder: String
    @Binding var text: String
    let highlights: [EventTitleHighlight]
    @Binding var focus: Bool
    let isInvalid: Bool

    var body: some View {
        HighlightedTextField(
            placeholder: placeholder,
            text: $text,
            highlights: highlights,
            focus: $focus
        )
        .padding(4)
        .overlay { InputBorder(isInvalid: isInvalid) }
    }
}

private class FocusTextField: NSTextField {

    @Binding private var focus: Bool

    init(focus: Binding<Bool>) {
        _focus = focus
        super.init(frame: .zero)
    }

    // textDidBeginEditing only triggers after a key press
    override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became {
            focus = true
        }
        return became
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        focus = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct HighlightedTextField: NSViewRepresentable {

    let placeholder: String
    @Binding var text: String
    let highlights: [EventTitleHighlight]
    @Binding var focus: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSTextField {
        let textField = FocusTextField(focus: $focus)
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.font = .systemFont(ofSize: 13)
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

    func updateNSView(_ textField: NSTextField, context: Context) {
        context.coordinator.parent = self
        if textField.stringValue != text {
            textField.stringValue = text
        }
        applyHighlights(highlights, to: textField)

        if focus, textField.currentEditor() == nil {
            DispatchQueue.main.async {
                textField.window?.makeFirstResponder(textField)
            }
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: HighlightedTextField

        init(parent: HighlightedTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
    }
}

private func applyHighlights(_ highlights: [EventTitleHighlight], to textField: NSTextField) {
    let fullRange = NSRange(location: 0, length: textField.stringValue.utf16.count)
    let attributedString = NSMutableAttributedString(
        string: textField.stringValue,
        attributes: [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.textColor,
        ]
    )

    for highlight in highlights where NSMaxRange(highlight.range) <= fullRange.length {
        attributedString.addAttributes([
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: highlight.color,
        ], range: highlight.range)
    }

    if let editor = textField.currentEditor() as? NSTextView {
        let selection = editor.selectedRange()
        editor.textStorage?.setAttributedString(attributedString)
        editor.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: NSColor.textColor,
        ]
        editor.setSelectedRange(selection)
    } else {
        textField.attributedStringValue = attributedString
    }
}
