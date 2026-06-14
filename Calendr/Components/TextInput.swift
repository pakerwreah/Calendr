//
//  TextInput.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import SwiftUI

struct TextInput: View {

    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding? = nil
    var isInvalid: Bool = false

    @FocusState private var defaultFocus: Bool

    private var textColor: Color { Color(nsColor: .textColor) }
    private var font: Font { .system(size: 13) }

    private var resolvedFocus: FocusState<Bool>.Binding {
        focus ?? $defaultFocus
    }

    var body: some View {
        TextField(placeholder, text: $text)
            .focused(resolvedFocus)
            .font(font)
            .foregroundStyle(textColor)
            .textFieldStyle(.plain)
            .padding(4)
            .overlay { InputBorder(isInvalid: isInvalid) }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Valid") {
    @Previewable @State var text: String = ""
    TextInput(placeholder: "Title", text: $text)
        .frame(width: 200)
        .fixedSize()
        .padding()
}

#Preview("Invalid") {
    @Previewable @State var text: String = "invalid text"
    TextInput(placeholder: "Invalid", text: $text, isInvalid: true)
        .frame(width: 200)
        .fixedSize()
        .padding()
}

#endif
