//
//  TextArea.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import SwiftUI

struct TextArea: View {

    let placeholder: String
    @Binding var text: String

    private var textColor: Color { Color(nsColor: .textColor) }
    private var font: Font { .system(size: 13) }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(font)
                .foregroundStyle(textColor)
                .padding(.vertical, 4)
                .overlay { InputBorder() }

            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .foregroundStyle(.placeholder)
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview {
    @Previewable @State var text: String = ""
    TextArea(placeholder: "Notes", text: $text)
        .frame(width: 200, height: 60)
        .fixedSize()
        .padding()

}

#endif
