//
//  EventEditorViewModelTests.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventEditorViewModelTests {

    let dateProvider = MockDateProvider(
        now: .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30)
    )

    @Test func testViewModel_initialState() {

        let calendarService = MockCalendarServiceProvider()
        let start = dateProvider.now

        let viewModel = makeViewModel(
            startDate: start,
            calendarService: calendarService
        )

        #expect(viewModel.title == "")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12, minute: 0))
        #expect(viewModel.isAllDay == false)
        #expect(viewModel.location == "")
        #expect(viewModel.url == "")
        #expect(viewModel.notes == "")
        #expect(viewModel.error == nil)
        #expect(viewModel.isErrorVisible == false)
        #expect(viewModel.hasValidInput == false)
        #expect(viewModel.isCloseConfirmationVisible == false)
        #expect(viewModel.calendarSections.isEmpty)
        #expect(viewModel.selectedCalendarId == nil)
        #expect(viewModel.selectedCalendarColor == .clear)
    }

    @Test func testViewModel_validTitle() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.hasValidInput == false)

        viewModel.title = "   "
        #expect(viewModel.hasValidInput == false)

        viewModel.title = "Meeting"
        #expect(viewModel.hasValidInput)
    }

    @Test(arguments: ["14", "2pm", "14:00"])
    func testViewModel_naturalLanguageTitle_setsTomorrowAtTwoPM(_ time: String) {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner with mom tomorrow at \(time)"

        #expect(viewModel.title == "Dinner with mom tomorrow at \(time)")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 15))
        #expect(viewModel.titleHighlights.count == 2)
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesDateBeforeTimeIsEntered() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner with mom in a week"

        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 11))

        viewModel.title += " at 14"

        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesYesterday() {

        let viewModel = makeViewModel()

        viewModel.title = "Retrospective yesterday"

        #expect(viewModel.parsedEventTitle == "Retrospective")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 24, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesInNumberOfDays() {

        let viewModel = makeViewModel()

        viewModel.title = "Call in 3 days"

        #expect(viewModel.parsedEventTitle == "Call")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 28, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesTimeWithoutDate() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner at 14"

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_fullDayChecksAllDay() {

        let viewModel = makeViewModel()

        viewModel.title = "Holiday in a week full day"

        #expect(viewModel.parsedEventTitle == "Holiday")
        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 11, day: 1, at: .start))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemPurple])
    }

    @Test func testViewModel_naturalLanguageTitle_durationSetsEndTime() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner tomorrow at 14 for 2 hours"

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 16))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange, .systemGreen])
    }

    @Test func testViewModel_naturalLanguageTitle_durationSupportsSingularDay() {

        let viewModel = makeViewModel()

        viewModel.title = "Retreat for 4 day"

        #expect(viewModel.parsedEventTitle == "Retreat")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_allDayDurationUsesInclusiveEndDate() {

        let viewModel = makeViewModel()

        viewModel.title = "Retreat tomorrow full day for 4 days"

        #expect(viewModel.parsedEventTitle == "Retreat")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_removingFullDayRestoresTimedState() {

        let viewModel = makeViewModel()

        viewModel.title = "Holiday tomorrow full day"
        #expect(viewModel.isAllDay)

        viewModel.title = "Holiday tomorrow"

        #expect(viewModel.isAllDay == false)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDurationRestoresPreviousDuration() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner tomorrow at 14 for 4 hours"
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 18))

        viewModel.title = "Dinner tomorrow at 14"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_removingAllDayDurationRestoresOneDay() {

        let viewModel = makeViewModel()

        viewModel.title = "Holiday tomorrow full day for 4 days"
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, at: .start))

        viewModel.title = "Holiday tomorrow full day"

        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_removingAllDayAndDurationRestoresTimedState() {

        let viewModel = makeViewModel()

        viewModel.title = "Holiday tomorrow full day for 4 days"

        viewModel.title = "Holiday tomorrow"

        #expect(viewModel.isAllDay == false)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateRestoresOriginalDate() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner tomorrow at 14"
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))

        viewModel.title = "Dinner at 14"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_removingTimeRestoresOriginalTime() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner tomorrow at 14"

        viewModel.title = "Dinner tomorrow"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateAndTimeRestoresInitialState() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner tomorrow at 14"

        viewModel.title = "Dinner"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingTimeKeepsParsedDuration() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner tomorrow at 14 for 2 hours"

        viewModel.title = "Dinner tomorrow for 2 hours"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 13))
    }

    @Test func testViewModel_naturalLanguageTitle_removingWeekdayRestoresOriginalDate() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner next Saturday"
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 11))

        viewModel.title = "Dinner"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateFromAllDayRestoresOriginalDay() {

        let viewModel = makeViewModel()

        viewModel.title = "Holiday tomorrow full day"

        viewModel.title = "Holiday full day"

        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesDayFirstLocale() {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        viewModel.title = "Dinner 7.8."

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 7, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesMonthFirstLocale() {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "en_US"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        viewModel.title = "Dinner 7.8."

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 7, day: 8, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_onWeekdayUsesNearestOccurrence() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner on Saturday at 14"

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_atWeekdayUsesNearestOccurrence() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner with mom at friday"

        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 31, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 31, hour: 12))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue])
    }

    @Test func testViewModel_naturalLanguageTitle_atWeekdayWithTimeRange() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner with mom at friday from 12 to 23"

        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 31, hour: 12))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 31, hour: 23))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_nextWeekdayUsesFollowingOccurrence() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner next Saturday at 14"

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_fuzzyMatchesMisspelledWeekday() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner on satruday at 14"

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_supportsWeekdayAbbreviation() {

        let viewModel = makeViewModel()

        viewModel.title = "Brunch on Sun"

        #expect(viewModel.parsedEventTitle == "Brunch")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_fuzzyMatchesCalendarAndCleansSavedTitle() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "family", title: "Přátelé a rodina", color: .systemPink),
            .make(id: "work", title: "Work", color: .systemBlue),
        ]
        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Dinner with mom in a week at 14 /rodina"

        #expect(viewModel.title == "Dinner with mom in a week at 14 /rodina")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.selectedCalendarId == "family")
        #expect(viewModel.matchedCalendarTitle == "Přátelé a rodina")
        #expect(viewModel.selectedCalendarColor == .systemPink)
        #expect(viewModel.titleHighlights.count == 3)
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange, .systemPink])

        viewModel.saveEvent()

        #expect(lastValue?.title == "Dinner with mom")
        #expect(lastValue?.calendar == "family")
        #expect(lastValue?.start == .make(year: 2025, month: 11, day: 1, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_fuzzyMatchesMisspelledCalendarWord() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "family", title: "Přátelé a rodina", color: .systemPink),
            .make(id: "work", title: "Work", color: .systemBlue),
        ]
        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Dinner with mom /rodna"

        #expect(viewModel.selectedCalendarId == "family")
        #expect(viewModel.matchedCalendarTitle == "Přátelé a rodina")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
    }

    @Test func testViewModel_naturalLanguageTitle_removingCalendarInstructionRestoresDefault() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "family", title: "Přátelé a rodina", color: .systemPink),
            .make(id: "work", title: "Work", color: .systemBlue),
        ]
        calendarService.m_defaultCalendarId = "work"
        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Dinner with mom /rodina"
        #expect(viewModel.selectedCalendarId == "family")

        viewModel.title = "Dinner with mom"

        #expect(viewModel.selectedCalendarId == "work")
        #expect(viewModel.matchedCalendarTitle == nil)
    }

    @Test func testViewModel_naturalLanguageTitle_usesSelectedTimeZone() {

        let timeZone = TimeZone(identifier: "America/New_York")!
        let dateProvider = MockDateProvider(
            calendar: .gregorian.with(timeZone: timeZone),
            now: .make(year: 2025, month: 10, day: 25, hour: 10, timeZone: timeZone)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        viewModel.title = "Dinner with mom tomorrow at 14:00"

        #expect(viewModel.title == "Dinner with mom tomorrow at 14:00")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14, timeZone: timeZone))
    }

    @Test func testViewModel_naturalLanguageTitle_leavesOrdinaryTitleUntouched() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner with mom"

        #expect(viewModel.title == "Dinner with mom")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
    }

    @Test(arguments: ["from 14 to 16", "at 14 until 16"])
    func testViewModel_naturalLanguageTitle_endTimeRangeSetsStartAndEnd(_ instruction: String) {

        let viewModel = makeViewModel()

        viewModel.title = "Workshop tomorrow \(instruction)"

        #expect(viewModel.parsedEventTitle == "Workshop")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 16))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_endTimeRangeCanCrossMidnight() {

        let viewModel = makeViewModel()

        viewModel.title = "Deployment tomorrow from 22 to 1"

        #expect(viewModel.parsedEventTitle == "Deployment")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 22))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 27, hour: 1))
    }

    @Test func testViewModel_naturalLanguageTitle_removingEndTimeRestoresOriginalDuration() {

        let viewModel = makeViewModel()

        viewModel.title = "Workshop from 14 to 18"
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 18))

        viewModel.title = "Workshop at 14"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesNoonAndMidnight() {

        let noonViewModel = makeViewModel()
        noonViewModel.title = "Lunch tomorrow at noon"

        #expect(noonViewModel.parsedEventTitle == "Lunch")
        #expect(noonViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 12))

        let midnightViewModel = makeViewModel()
        midnightViewModel.title = "Deployment tomorrow at midnight"

        #expect(midnightViewModel.parsedEventTitle == "Deployment")
        #expect(midnightViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 0))
        #expect(midnightViewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 1))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesMorningAndEvening() {

        let morningViewModel = makeViewModel()
        morningViewModel.title = "Coffee tomorrow morning"

        #expect(morningViewModel.parsedEventTitle == "Coffee")
        #expect(morningViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 9))

        let eveningViewModel = makeViewModel()
        eveningViewModel.title = "Dinner tomorrow in the evening"

        #expect(eveningViewModel.parsedEventTitle == "Dinner")
        #expect(eveningViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 18))
    }

    @Test func testViewModel_naturalLanguageTitle_eveningCanQualifyNumericTime() {

        let viewModel = makeViewModel()

        viewModel.title = "Dinner tomorrow at 7 in the evening"

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 19))
    }

    @Test func testViewModel_naturalLanguageTitle_relativeStartUsesCurrentTime() {

        let viewModel = makeViewModel()

        viewModel.title = "Call in 2 hours"

        #expect(viewModel.parsedEventTitle == "Call")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 12, minute: 30))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 13, minute: 30))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_removingRelativeStartRestoresInitialDateAndTime() {

        let viewModel = makeViewModel()

        viewModel.title = "Call in 2 hours"
        viewModel.title = "Call"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_namedMonthDate() {

        let viewModel = makeViewModel()

        viewModel.title = "Birthday on August 12 at noon"

        #expect(viewModel.parsedEventTitle == "Birthday")
        #expect(viewModel.startDate == .make(year: 2025, month: 8, day: 12, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_namedDayMonthDateWithYear() {

        let viewModel = makeViewModel()

        viewModel.title = "Conference 12 August 2027 at 9"

        #expect(viewModel.parsedEventTitle == "Conference")
        #expect(viewModel.startDate == .make(year: 2027, month: 8, day: 12, hour: 9))
    }

    @Test func testViewModel_naturalLanguageTitle_namedDateUsesEnglishWithNonEnglishLocale() {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        viewModel.title = "Dinner 12 August at 14"

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 12, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_doesNotRecognizeLocalizedMonthNames() {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(startDate: dateProvider.now, dateProvider: dateProvider)

        viewModel.title = "Dinner 12 srpna at 14"

        #expect(viewModel.parsedEventTitle == "Dinner 12 srpna")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 6, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_removingNamedDateRestoresOriginalDate() {

        let viewModel = makeViewModel()

        viewModel.title = "Birthday on August 12 at noon"
        viewModel.title = "Birthday at noon"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 12))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 13))
    }

    @Test func testViewModel_naturalLanguageTitle_neverParsesFirstWordAsInstruction() {

        for title in [
            "Tomorrow planning",
            "August 12 birthday",
            "At 14 lunch",
            "In 2 hours call",
            "Full day workshop",
            "For 2 hours lecture",
        ] {
            let viewModel = makeViewModel()

            viewModel.title = title

            #expect(viewModel.parsedEventTitle == title)
            #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
            #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
            #expect(viewModel.titleHighlights.isEmpty)
        }
    }

    @Test func testViewModel_dateRange_timed_endEqualStart_invalid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Meeting"
        viewModel.endDate = viewModel.startDate

        #expect(viewModel.hasValidDateRange == false)
        #expect(viewModel.hasValidInput == false)
    }

    @Test func testViewModel_dateRange_timed_endAfterStart_valid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30),
            calendarService: calendarService
        )

        viewModel.title = "Meeting"
        viewModel.endDate = .make(year: 2025, month: 10, day: 25, hour: 13, minute: 0)

        #expect(viewModel.hasValidDateRange)
        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_dateRange_allDay_sameDay_valid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Holiday"
        viewModel.isAllDay = true
        viewModel.startDate = .make(year: 2025, month: 10, day: 25, at: .start)
        viewModel.endDate = .make(year: 2025, month: 10, day: 25, at: .start)

        #expect(viewModel.hasValidDateRange)
        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_dateRange_allDay_endBeforeStart_invalid() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Holiday"
        viewModel.isAllDay = true
        viewModel.startDate = .make(year: 2025, month: 10, day: 25, at: .start)
        viewModel.endDate = .make(year: 2025, month: 10, day: 24, at: .start)

        #expect(viewModel.hasValidDateRange == false)
        #expect(viewModel.hasValidInput == false)
    }

    @Test func testViewModel_isAllDay_toggleOn_stripsTimeAndFixesEnd() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 14, minute: 30)
        )

        viewModel.endDate = .make(year: 2025, month: 10, day: 24, hour: 16)

        viewModel.isAllDay = true

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, at: .start))
    }

    @Test func testViewModel_isAllDay_toggleOff_setsEndOneHourAfterStartWhenNeeded() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 14)
        )

        viewModel.isAllDay = true
        viewModel.isAllDay = false

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 1, minute: 0))
    }

    @Test func testViewModel_saveEvent_withInvalidInput_shouldNotCallService() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.saveEvent()
        #expect(lastValue == nil)

        viewModel.title = "Meeting"
        viewModel.endDate = viewModel.startDate
        viewModel.saveEvent()
        #expect(lastValue == nil)
    }

    @Test func testViewModel_saveEvent_withValidInput() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let start: Date = .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0)
        let end: Date = .make(year: 2025, month: 10, day: 25, hour: 12, minute: 30)

        let viewModel = makeViewModel(startDate: start, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "  Team sync  "
        viewModel.endDate = end
        viewModel.location = "  Office  "
        viewModel.url = "https://example.com"
        viewModel.notes = "  Agenda  "
        viewModel.selectedCalendarId = "cal-1"
        viewModel.saveEvent()

        #expect(lastValue?.title == "Team sync")
        #expect(lastValue?.calendar == "cal-1")
        #expect(lastValue?.start == start)
        #expect(lastValue?.end == end)
        #expect(lastValue?.isAllDay == false)
        #expect(lastValue?.location == "Office")
        #expect(lastValue?.url?.absoluteString == "https://example.com")
        #expect(lastValue?.notes == "Agenda")
        #expect(lastValue?.alertOffset == nil)
        #expect(lastValue?.timeZone == dateProvider.calendar.timeZone)
    }

    @Test func testViewModel_initialState_selectedTimeZoneIsDateProviderTimeZone() {

        let timeZone = TimeZone(secondsFromGMT: -5 * 3600)!
        dateProvider.m_calendar = Calendar.gregorian.with(timeZone: timeZone)

        let viewModel = makeViewModel()

        #expect(viewModel.selectedTimeZoneIdentifier == timeZone.identifier)
    }

    @Test func testViewModel_saveEvent_passesSelectedTimeZone() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedTimeZoneIdentifier = "America/Sao_Paulo"
        viewModel.saveEvent()

        #expect(lastValue?.timeZone.identifier == "America/Sao_Paulo")
    }

    @Test func testViewModel_changingTimeZone_preservesWallClockTime() {

        let oldTimeZone = TimeZone(secondsFromGMT: 3 * 3600)!
        dateProvider.m_calendar = Calendar.gregorian.with(timeZone: oldTimeZone)

        let start: Date = .make(year: 2025, month: 10, day: 25, hour: 14, minute: 30, timeZone: oldTimeZone)

        let viewModel = makeViewModel(startDate: start)

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0, timeZone: oldTimeZone))

        viewModel.selectedTimeZoneIdentifier = "UTC"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0, timeZone: .utc))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 16, minute: 0, timeZone: .utc))
    }

    @Test func testViewModel_init_roundsStartUpToNextHour() {

        let onTheHour: Date = .make(year: 2025, month: 10, day: 25, hour: 10, minute: 0)
        let withMinutes: Date = .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30)

        let onTheHourViewModel = makeViewModel(startDate: onTheHour)
        let withMinutesViewModel = makeViewModel(startDate: withMinutes)

        #expect(onTheHourViewModel.startDate == onTheHour)
        #expect(withMinutesViewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0))
    }

    @Test func testViewModel_changingEndDate_tracksDuration() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.endDate = .make(year: 2025, month: 10, day: 25, hour: 12, minute: 0)

        viewModel.startDate = .make(year: 2025, month: 10, day: 25, hour: 13, minute: 0)

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0))
    }

    @Test func testViewModel_changingEndDate_invalid_doesNotUpdateDuration() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.endDate = .make(year: 2025, month: 10, day: 25, hour: 12, minute: 0)
        viewModel.endDate = viewModel.startDate

        viewModel.startDate = .make(year: 2025, month: 10, day: 25, hour: 13, minute: 0)

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0))
    }

    @Test func testViewModel_isAllDay_changingStartDate_fixesInvalidEnd() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.isAllDay = true
        viewModel.startDate = .make(year: 2025, month: 10, day: 26, at: .start)

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, at: .start))
    }

    @Test func testViewModel_isAllDay_changingStartDate_keepsValidEnd() {

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10)
        )

        viewModel.isAllDay = true

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, at: .start))

        viewModel.startDate = .make(year: 2025, month: 10, day: 26, at: .start)

        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, at: .start))
    }

    @Test func testViewModel_initialState_selectedAlertIsNone() {

        let viewModel = makeViewModel()

        #expect(viewModel.selectedAlert == .none)
    }

    @Test func testViewModel_saveEvent_withNoAlertSelected() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == nil)
    }

    @Test func testViewModel_saveEvent_withAlertSelected() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedAlert = .tenMinutesBefore
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == -600)
    }

    @Test func testViewModel_saveEvent_withAtTimeOfEventAlert() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedAlert = .atTimeOfEvent
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == 0)
    }

    @Test func testViewModel_saveEvent_withError() {

        let calendarService = FailingEventCalendarService()
        calendarService.m_calendars = [.make()]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.title = "Meeting"
        viewModel.saveEvent()

        #expect(viewModel.isErrorVisible)
        #expect(viewModel.error?.localizedDescription == "Creation failed")

        viewModel.dismissError()
        #expect(viewModel.isErrorVisible == false)
        #expect(viewModel.error == nil)
    }

    @Test func testViewModel_saveEvent_withSuccess_shouldCloseWindow() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should close window")

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "Meeting"
        viewModel.saveEvent()

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_saveEvent_withError_shouldNotCloseWindow() async {

        let calendarService = FailingEventCalendarService()
        calendarService.m_calendars = [.make()]

        let expectation = expectation(description: "Should not close window")
        expectation.isInverted = true

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "Meeting"
        viewModel.saveEvent()

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_withCloseRequested_withInvalidInput_shouldCloseWindow() async {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = expectation.fulfill

        #expect(viewModel.requestWindowClose())
        #expect(viewModel.isCloseConfirmationVisible == false)

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_withCloseRequested_withValidInput_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let closeExpectation = expectation(description: "Should close window")

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "Meeting"

        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])

        viewModel.onCloseConfirmed = closeExpectation.fulfill
        viewModel.confirmClose()

        await fulfillment(of: [closeExpectation])
        #expect(viewModel.isCloseConfirmationVisible == false)
    }

    @Test func testViewModel_withCloseRequested_withInvalidDateRange_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.title = "Meeting"
        viewModel.notes = "Agenda"
        viewModel.endDate = viewModel.startDate

        #expect(viewModel.hasValidInput == false)
        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])
    }

    @Test func testViewModel_withCloseRequested_withNotesOnly_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.notes = "Some notes"

        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])
    }

    @Test func testViewModel_withCloseRequested_withLocationOnly_shouldAskForConfirmation() async {

        let notCloseExpectation = expectation(description: "Should not close window")
        notCloseExpectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = notCloseExpectation.fulfill
        viewModel.location = "Office"

        #expect(viewModel.requestWindowClose() == false)
        #expect(viewModel.isCloseConfirmationVisible)

        await fulfillment(of: [notCloseExpectation])
    }

    @Test func testViewModel_withCloseRequested_withWhitespaceOnly_shouldCloseWindow() async {

        let expectation = expectation(description: "Should not call confirmation callback")
        expectation.isInverted = true

        let viewModel = makeViewModel()

        viewModel.onCloseConfirmed = expectation.fulfill
        viewModel.title = "   "
        viewModel.notes = "   "

        #expect(viewModel.requestWindowClose())
        #expect(viewModel.isCloseConfirmationVisible == false)

        await fulfillment(of: [expectation])
    }

    @Test func testViewModel_calendars_withDefault_shouldSelectDefaultCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-2"

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.selectedCalendarId == "cal-2")
    }

    @Test func testViewModel_calendars_shouldGroupByAccount() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", account: "iCloud", title: "Work"),
            .make(id: "cal-2", account: "iCloud", title: "Personal"),
            .make(id: "cal-3", account: "Google", title: "Tasks"),
        ]

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.calendarSections.count == 2)
        #expect(viewModel.calendarSections[0].account.title == "Google")
        #expect(viewModel.calendarSections[1].account.title == "iCloud")
    }

    @Test func testViewModel_saveEvent_shouldPassSelectedCalendar() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-1"

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = "Meeting"
        viewModel.selectedCalendarId = "cal-2"
        viewModel.saveEvent()

        #expect(lastValue?.calendar == "cal-2")
    }

    // MARK: - Factory

    func makeViewModel(
        startDate: Date? = nil,
        dateProvider: DateProviding? = nil,
        calendarService: CalendarServiceProviding = MockCalendarServiceProvider()
    ) -> EventEditorViewModel {
        EventEditorViewModel(
            startDate: .init(date: startDate ?? self.dateProvider.now),
            dateProvider: dateProvider ?? self.dateProvider,
            calendarService: calendarService,
            scheduler: CurrentThreadScheduler.instance
        )
    }
}

private class FailingEventCalendarService: MockCalendarServiceProvider {

    override func createEvent(
        title: String,
        calendar: String,
        start: Date,
        end: Date,
        isAllDay: Bool,
        location: String?,
        url: URL?,
        notes: String?,
        alertOffset: TimeInterval?,
        timeZone: TimeZone
    ) -> Completable {
        .error(.unexpected("Creation failed"))
    }
}
