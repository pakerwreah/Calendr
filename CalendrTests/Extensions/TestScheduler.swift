//
//  TestScheduler.swift
//  CalendrTests
//
//  Created by Paker on 27/12/20.
//

import RxTest

extension TestScheduler {
    convenience init() {
        self.init(initialClock: 0)
    }
}
