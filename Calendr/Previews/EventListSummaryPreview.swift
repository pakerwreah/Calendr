//
//  EventListSummaryPreview.swift
//  Calendr
//
//  Created by Paker on 26/10/2025.
//

#if DEBUG

import SwiftUI
import RxSwift

struct EventListSummaryPreview: PreviewProvider {

    static var previews: some View {
        EventListSummaryView(
            summary: .just(
                EventListSummary(
                    overdue: EventListSummaryItem(
                        colors: Set([.systemMint]),
                        count: 5
                    ),
                    allday: EventListSummaryItem(
                        colors: Set([.systemGreen, .systemOrange]),
                        count: 10
                    ),
                    today: EventListSummaryItem(
                        colors: Set([.systemTeal, .systemPink, .systemYellow]),
                        count: 15
                    ),
                )
            ),
            scaling: .just(1.5)
        )
        .preview()
        .frame(width: 310)
        .fixedSize()
        .padding(5)
    }
}

#endif
