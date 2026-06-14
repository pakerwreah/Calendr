//
//  InputBorder.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import SwiftUI

struct InputBorder: View {

    var isInvalid: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(
                isInvalid ? Color(nsColor: .systemRed) : Color(nsColor: .tertiaryLabelColor),
                style: isInvalid
                    ? StrokeStyle(lineWidth: 1, dash: [4, 2])
                    : StrokeStyle(lineWidth: 1)
            )
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Valid") {
    InputBorder()
        .frame(width: 200, height: 24)
        .padding()
}

#Preview("Invalid") {
    InputBorder(isInvalid: true)
        .frame(width: 200, height: 24)
        .padding()
}

#endif
