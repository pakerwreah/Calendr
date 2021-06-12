//
//  TrackedHistoricalScheduler.swift
//  CalendrTests
//
//  Created by Paker on 08/03/2021.
//

import Foundation
import RxSwift

class TrackedHistoricalScheduler : VirtualTimeScheduler<HistoricalSchedulerTimeConverter> {

    var log: [VirtualTime] = []

    init(initialClock: RxTime = Date(timeIntervalSince1970: 0)) {
        super.init(initialClock: initialClock, converter: .init())
    }

    /// Adjusts time of scheduling (and log it ☝🏻) before adding item to schedule queue.
    public override func adjustScheduledTime(_ time: VirtualTime) -> VirtualTime {
        let time = super.adjustScheduledTime(time)
        log.append(time)
        return time
    }
}
