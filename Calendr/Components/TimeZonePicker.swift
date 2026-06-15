//
//  TimeZonePicker.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import SwiftUI

struct TimeZonePicker: View {

    @Binding var selectedIdentifier: String

    var body: some View {
        Picker("", selection: $selectedIdentifier) {
            ForEach(TimeZone.options(for: .now), id: \.identifier) { timeZone in
                Text(timeZone.displayName(for: .now))
                    .tag(timeZone.identifier)
            }
        }
        .labelsHidden()
    }
}

#if DEBUG

#Preview {
    @Previewable @State var timeZone: String = TimeZone.current.identifier
    TimeZonePicker(selectedIdentifier: $timeZone)
        .fixedSize()
        .padding()
}

#endif
