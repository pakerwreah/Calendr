//
//  DateTimeInput.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import SwiftUI

struct DateTimeInput: View {

    @Binding var date: Date
    var showTime: Bool
    var timeZone: TimeZone = .current
    var isInvalid: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.field)
                .labelsHidden()

            if showTime {
                DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.field)
                    .labelsHidden()
            }
        }
        .environment(\.timeZone, timeZone)
        .overlay { isInvalid ? InputBorder(isInvalid: true) : nil }
    }
}

// MARK: - Preview

#if DEBUG

#Preview("Valid") {
    @Previewable @State var date = Date.now
    DateTimeInput(date: $date, showTime: true)
        .padding()
}

#Preview("Invalid") {
    @Previewable @State var date = Date.now
    DateTimeInput(date: $date, showTime: true, isInvalid: true)
        .padding()
}

#endif
