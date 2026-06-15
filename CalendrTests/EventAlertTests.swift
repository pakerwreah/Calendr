//
//  EventAlertTests.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import XCTest
@testable import Calendr

class EventAlertTests: XCTestCase {

    func testEventAlert_relativeOffset() {
        XCTAssertNil(EventAlert.none.relativeOffset)
        XCTAssertEqual(EventAlert.atTimeOfEvent.relativeOffset, 0)
        XCTAssertEqual(EventAlert.fiveMinutesBefore.relativeOffset, -300)
        XCTAssertEqual(EventAlert.tenMinutesBefore.relativeOffset, -600)
        XCTAssertEqual(EventAlert.fifteenMinutesBefore.relativeOffset, -900)
        XCTAssertEqual(EventAlert.thirtyMinutesBefore.relativeOffset, -1800)
        XCTAssertEqual(EventAlert.oneHourBefore.relativeOffset, -3600)
        XCTAssertEqual(EventAlert.twoHoursBefore.relativeOffset, -7200)
        XCTAssertEqual(EventAlert.oneDayBefore.relativeOffset, -86400)
        XCTAssertEqual(EventAlert.twoDaysBefore.relativeOffset, -172800)
    }
}
