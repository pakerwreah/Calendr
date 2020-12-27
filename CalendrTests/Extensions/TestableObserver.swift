//
//  TestableObserver.swift
//  CalendrTests
//
//  Created by Paker on 27/12/20.
//

import RxTest

extension TestableObserver {
    var values: [Element] {
        events.compactMap { $0.value.element }
    }
}
