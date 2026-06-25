//
//  EventAlertTests.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import Foundation
import Testing
@testable import Calendr

class EventAlertTests {

    @Test func testEventAlert_relativeOffset() {
        #expect(EventAlert.none.relativeOffset == nil)
        #expect(EventAlert.atTimeOfEvent.relativeOffset == 0)
        #expect(EventAlert.fiveMinutesBefore.relativeOffset == -300)
        #expect(EventAlert.tenMinutesBefore.relativeOffset == -600)
        #expect(EventAlert.fifteenMinutesBefore.relativeOffset == -900)
        #expect(EventAlert.thirtyMinutesBefore.relativeOffset == -1800)
        #expect(EventAlert.oneHourBefore.relativeOffset == -3600)
        #expect(EventAlert.twoHoursBefore.relativeOffset == -7200)
        #expect(EventAlert.oneDayBefore.relativeOffset == -86400)
        #expect(EventAlert.twoDaysBefore.relativeOffset == -172800)
    }
}
