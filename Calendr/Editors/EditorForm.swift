//
//  EditorForm.swift
//  Calendr
//
//  Created by Patrik Fonos on 14/10/2026.
//

import SwiftUI

// Building blocks for the event / reminder editors, modeled after the grouped
// form style used by System Settings and the native Calendar / Reminders apps.

struct EditorSection<Content: View>: View {

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius, style: .continuous)
                .fill(Color(nsColor: .quaternaryLabelColor).opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: EditorMetrics.cornerRadius, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

struct EditorDivider: View {

    var body: some View {
        Divider()
            .padding(.leading, EditorMetrics.dividerInset)
    }
}

struct EditorRow<Content: View>: View {

    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 8) {
            EditorIcon(systemImage: systemImage)

            Text(title)
                .lineLimit(1)

            Spacer(minLength: 12)

            content
        }
        .padding(.horizontal, EditorMetrics.horizontalPadding)
        .frame(minHeight: EditorMetrics.rowHeight)
    }
}

struct EditorTextFieldRow: View {

    let placeholder: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            EditorIcon(systemImage: systemImage)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
        }
        .padding(.horizontal, EditorMetrics.horizontalPadding)
        .frame(minHeight: EditorMetrics.rowHeight)
    }
}

struct EditorNotesRow: View {

    let placeholder: String
    @Binding var text: String

    private var font: Font { .system(size: 13) }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            EditorIcon(systemImage: "text.alignleft")
                .frame(height: EditorMetrics.rowHeight)

            ZStack(alignment: .topLeading) {
                EditorNotesTextView(text: $text)
                    .padding(.vertical, 8)

                if text.isEmpty {
                    Text(placeholder)
                        .font(font)
                        .foregroundStyle(.placeholder)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 72)
        }
        .padding(.horizontal, EditorMetrics.horizontalPadding)
    }
}

// Native text view so the scroller only shows up when the notes overflow,
// even with the "Always show scroll bars" system setting (TextEditor ignores it)
struct EditorNotesTextView: NSViewRepresentable {

    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator($text)
    }

    func makeNSView(context: Context) -> NSScrollView {

        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        guard let textView = scrollView.documentView as? NSTextView else {
            assertionFailure()
            return scrollView
        }
        textView.delegate = context.coordinator
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 13)
        textView.textColor = .textColor
        textView.isRichText = false
        textView.allowsUndo = true
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.string = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {

        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            textView.string = text
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {

        @Binding private var text: String

        init(_ text: Binding<String>) {
            self._text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text = textView.string
        }
    }
}

struct EditorIcon: View {

    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
            .frame(width: EditorMetrics.iconWidth)
    }
}

struct EditorHeader<Accessory: View>: View {

    let title: String
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            Spacer(minLength: 12)

            accessory
        }
    }
}

struct EditorFooter: View {

    let isSaveEnabled: Bool
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Spacer()

            Button(Strings.AccessRequired.cancel, role: .cancel) {
                NSApp.keyWindow?.performClose(nil)
            }
            .keyboardShortcut(.cancelAction)
            .controlSize(.large)

            Button(Strings.Editor.save, action: onSave)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isSaveEnabled)
                .keyboardShortcut(.defaultAction)
        }
    }
}

enum EditorMetrics {

    static let cornerRadius: CGFloat = 8
    static let rowHeight: CGFloat = 34
    static let horizontalPadding: CGFloat = 10
    static let iconWidth: CGFloat = 18
    static let dividerInset: CGFloat = horizontalPadding + iconWidth + 8
    static let sectionSpacing: CGFloat = 12
    static let padding: CGFloat = 20
}

// MARK: - Preview

#Preview("Editor Components") {
    @Previewable @State var text: String = ""

    VStack(spacing: 16) {

        EditorSection {
            EditorTextFieldRow(
                placeholder: "Title",
                systemImage: "tag",
                text: $text
            )
        }
        EditorSection {
            EditorTextFieldRow(
                placeholder: "Location",
                systemImage: "mappin.and.ellipse",
                text: $text
            )
            EditorDivider()
            EditorNotesRow(
                placeholder: "Notes",
                text: $text
            )
        }
    }
    .padding()
    .frame(width: 300)
}
