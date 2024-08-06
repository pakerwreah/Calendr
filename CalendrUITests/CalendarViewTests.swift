//
//  CalendarViewTests.swift
//  CalendrUITests
//
//  Created by Paker on 14/07/2021.
//

import XCTest

class CalendarViewTests: UITestCase {

    func testWeekDays() {

        XCTAssertEqual(Calendar.weekDays.map(\.text) , ["S", "M", "T", "W", "T", "F", "S"])
    }

    func testWeekNumbers() {

        XCTAssertEqual(Calendar.weekNumbers.map(\.text) , ["53", "1", "2", "3", "4", "5"])
    }

    // MARK: - Month selection

    func testMonth_withInitialState_shouldDisplayInitialMonth() {

        XCTAssertEqual(Main.title.value(), "Jan 2021")

        XCTAssertEqual(Calendar.dates.first?.value(), "27")
        XCTAssertEqual(Calendar.dates.prefix(6).dropFirst(4).map(\.text), ["31", "1"])
        XCTAssertEqual(Calendar.dates.suffix(7).dropLast(5).map(\.text), ["31", "1"])
        XCTAssertEqual(Calendar.dates.last?.value(), "6")
    }

    func testMonth_withNextButtonClicked_shouldDisplayNextMonth() {

        MenuBar.main.click()
        Main.nextBtn.click()

        XCTAssertEqual(Main.title.value(), "Feb 2021")

        XCTAssertEqual(Calendar.dates.prefix(2).map(\.text), ["31", "1"])
        XCTAssertEqual(Calendar.dates.suffix(14).dropLast(12).map(\.text), ["28", "1"])
        XCTAssertEqual(Calendar.dates.last?.value(), "13")
    }

    func testMonth_withPrevButton_shouldDisplayPreviousMonth() {

        MenuBar.main.click()
        Main.prevBtn.click()

        XCTAssertEqual(Main.title.value(), "Dec 2020")

        XCTAssertEqual(Calendar.dates.prefix(3).map(\.text), ["29", "30", "1"])
        XCTAssertEqual(Calendar.dates.suffix(10).dropLast(8).map(\.text), ["31", "1"])
        XCTAssertEqual(Calendar.dates.last?.value(), "9")
    }

    func testMonth_withResetButtonClicked_shouldDisplayInitialMonth() {

        MenuBar.main.click()
        Main.nextBtn.click()
        Main.nextBtn.click()

        XCTAssertEqual(Main.title.value(), "Mar 2021")

        Main.resetBtn.click()

        XCTAssertEqual(Main.title.value(), "Jan 2021")
        XCTAssertEqual(Calendar.dates.first?.value(), "27")
        XCTAssertEqual(Calendar.dates.last?.value(), "6")
    }

    // MARK: - Date selection

    func testDate_withPreviousMonthDateSelected_shouldDisplayPreviousMonth() {

        MenuBar.main.click()
        Calendar.dates.first?.click()

        XCTAssertEqual(Main.title.value(), "Dec 2020")
        XCTAssertEqual(Calendar.dates.first?.value(), "29")
        XCTAssertEqual(Calendar.dates.last?.value(), "9")
    }

    func testDate_withNextMonthDateSelected_shouldDisplayNextMonth() {

        MenuBar.main.click()
        Calendar.dates.last?.click()

        XCTAssertEqual(Main.title.value(), "Feb 2021")
        XCTAssertEqual(Calendar.dates.first?.value(), "31")
        XCTAssertEqual(Calendar.dates.last?.value(), "13")
    }

    func testDate_withLeftArrowTapped_shouldSelectPreviousDate() {

        MenuBar.main.click()

        Main.view.typeKey(.leftArrow, modifierFlags: [])

        XCTAssertEqual(Calendar.selected.value(), "31")
    }

    func testDate_withRightArrowTapped_shouldSelectNextDate() {

        MenuBar.main.click()

        Main.view.typeKey(.rightArrow, modifierFlags: [])

        XCTAssertEqual(Calendar.selected.value(), "2")
    }

    func testDate_withUpArrowTapped_shouldSelectPreviousWeek() {

        MenuBar.main.click()

        Main.view.typeKey(.upArrow, modifierFlags: [])

        XCTAssertEqual(Main.title.value(), "Dec 2020")
        XCTAssertEqual(Calendar.selected.value(), "25")
    }

    func testDate_withDownArrowTapped_shouldSelectNextWeek() {

        MenuBar.main.click()

        Main.view.typeKey(.downArrow, modifierFlags: [])

        XCTAssertEqual(Main.title.value(), "Jan 2021")
        XCTAssertEqual(Calendar.selected.value(), "8")
    }

    // MARK: - Date hover

    func testDate_withMouseHovered_shouldHoverDate() {

        MenuBar.main.click()

        Calendar.dates[0].hover()
        XCTAssertEqual(Calendar.hovered.value(), "27")

        Calendar.dates[1].hover()
        XCTAssertEqual(Calendar.hovered.value(), "28")

        Calendar.dates[10].hover()
        XCTAssertEqual(Calendar.hovered.value(), "6")

        Main.view.outside.hover()
        XCTAssertFalse(Calendar.hovered.exists)
    }

    func testDate_withMouseHovered_shouldShowDateEvents() {

        MenuBar.main.click()

        Calendar.dates[8].hover()
        XCTAssertEqual(EventList.eventsTexts, [["Test event 🚧", "4 - 7 January"]])

        Calendar.dates[15].hover()
        XCTAssertEqual(EventList.eventsTexts, [["Test event 🚧", "11 - 14 January"]])

        Main.view.outside.hover()
        XCTAssertEqual(EventList.eventsTexts, [
            [
                "Drink some tea 🫖",
                "15:30 - 15:50"
            ],
            [
                "Update Calendr screenshot 📷",
                "16:00 - 17:00"
            ],
            [
                "Some meeting 👔",
                "zoom.us/j/9999999999",
                "17:00 - 18:00"
            ],
            [
                "Take the trash out",
                "19:00"
            ]
        ])
    }

    // MARK: - Event dots

    func testDate_withInitialState_shouldDisplayEventDots() {

        XCTAssertEqual(Calendar.events.count, 4)
    }

    func testSearch_shouldFilterEvents() {

        MenuBar.main.click()
        XCTAssertFalse(Main.searchInput.exists)

        Main.view.typeKey("f", modifierFlags: [.command])
        XCTAssertTrue(Main.searchInput.exists)
        XCTAssertTrue(Main.searchInput.hasFocus)

        Main.searchInput.typeText("some")
        XCTAssertEqual(Calendar.events.count, 2)
        XCTAssertEqual(EventList.eventsTexts, [
            [
                "Drink some tea 🫖",
                "15:30 - 15:50"
            ],
            [
                "Some meeting 👔",
                "zoom.us/j/9999999999",
                "17:00 - 18:00"
            ]
        ])

        Main.searchInput.replaceText("zoom")
        XCTAssertEqual(Calendar.events.count, 1)
        XCTAssertEqual(EventList.eventsTexts, [
            [
                "Some meeting 👔",
                "zoom.us/j/9999999999",
                "17:00 - 18:00"
            ]
        ])
    }
}

private extension UITestCase.EventList {

    static var eventsTexts: [[String?]] {
        events.map { $0.staticTexts.array.map(\.text) }
    }
}
