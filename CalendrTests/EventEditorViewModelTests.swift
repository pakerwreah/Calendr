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
        now: .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0)
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

    @Test func testViewModel_validTitle() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        #expect(viewModel.hasValidInput == false)

        await viewModel.setTitle("   ")
        #expect(viewModel.hasValidInput == false)

        await viewModel.setTitle("Meeting")
        #expect(viewModel.hasValidInput)
    }

    @Test(arguments: ["14", "2pm", "14:00"])
    func testViewModel_naturalLanguageTitle_setsTomorrowAtTwoPM(_ time: String) async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner with mom tomorrow at \(time)")

        #expect(viewModel.title == "Dinner with mom tomorrow at \(time)")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 15))
        #expect(viewModel.titleHighlights.count == 2)
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesDateBeforeTimeIsEntered() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner with mom in a week")

        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 11))

        await viewModel.setTitle("\(viewModel.title) at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesYesterday() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Retrospective yesterday")

        #expect(viewModel.parsedEventTitle == "Retrospective")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 24, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesInNumberOfDays() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Call in 3 days")

        #expect(viewModel.parsedEventTitle == "Call")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 28, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesTimeWithoutDate() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner at 14")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_fullDayChecksAllDay() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Holiday in a week full day")

        #expect(viewModel.parsedEventTitle == "Holiday")
        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 11, day: 1, at: .start))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemPurple])
    }

    @Test func testViewModel_naturalLanguageTitle_durationSetsEndTime() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner tomorrow at 14 for 2 hours")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 16))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange, .systemGreen])
    }

    @Test func testViewModel_naturalLanguageTitle_durationSupportsSingularDay() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Retreat for 4 day")

        #expect(viewModel.parsedEventTitle == "Retreat")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_allDayDurationUsesInclusiveEndDate() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Retreat tomorrow full day for 4 days")

        #expect(viewModel.parsedEventTitle == "Retreat")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_removingFullDayRestoresTimedState() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Holiday tomorrow full day")
        #expect(viewModel.isAllDay)

        await viewModel.setTitle("Holiday tomorrow")

        #expect(viewModel.isAllDay == false)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDurationRestoresPreviousDuration() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner tomorrow at 14 for 4 hours")
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 18))

        await viewModel.setTitle("Dinner tomorrow at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_removingAllDayDurationRestoresOneDay() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Holiday tomorrow full day for 4 days")
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, at: .start))

        await viewModel.setTitle("Holiday tomorrow full day")

        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_removingAllDayAndDurationRestoresTimedState() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Holiday tomorrow full day for 4 days")

        await viewModel.setTitle("Holiday tomorrow")

        #expect(viewModel.isAllDay == false)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateRestoresOriginalDate() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner tomorrow at 14")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))

        await viewModel.setTitle("Dinner at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_removingTimeRestoresOriginalTime() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner tomorrow at 14")

        await viewModel.setTitle("Dinner tomorrow")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateAndTimeRestoresInitialState() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner tomorrow at 14")

        await viewModel.setTitle("Dinner")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingTimeKeepsParsedDuration() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner tomorrow at 14 for 2 hours")

        await viewModel.setTitle("Dinner tomorrow for 2 hours")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 13))
    }

    @Test func testViewModel_naturalLanguageTitle_removingWeekdayRestoresOriginalDate() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner next Saturday")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 11))

        await viewModel.setTitle("Dinner")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateFromAllDayRestoresOriginalDay() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Holiday tomorrow full day")

        await viewModel.setTitle("Holiday full day")

        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesDayFirstLocale() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.setTitle("Dinner 7.8.")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 7, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesMonthFirstLocale() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "en_US"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.setTitle("Dinner 7.8.")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 7, day: 8, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesDayFirstLocale_withTimeOverlap() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.setTitle("Dinner at 7.8.")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 7, hour: 7))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesMonthFirstLocale_withTimeOverlap() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "en_US"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.setTitle("Dinner at 7.8.")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 7, day: 8, hour: 7))
    }

    @Test func testViewModel_naturalLanguageTitle_onWeekdayUsesNearestOccurrence() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner on Saturday at 14")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_atWeekdayUsesNearestOccurrence() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner with mom at friday")

        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 31, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 31, hour: 12))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue])
    }

    @Test func testViewModel_naturalLanguageTitle_atWeekdayWithTimeRange() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner with mom at friday from 12 to 23")

        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 31, hour: 12))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 31, hour: 23))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_nextWeekdayUsesFollowingOccurrence() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner next Saturday at 14")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_fuzzyMatchesMisspelledWeekday() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner on satruday at 14")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_supportsWeekdayAbbreviation() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Brunch on Sun")

        #expect(viewModel.parsedEventTitle == "Brunch")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_fuzzyMatchesCalendarAndCleansSavedTitle()  async{

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "family", title: "Přátelé a rodina", color: .systemPink),
            .make(id: "work", title: "Work", color: .systemBlue),
        ]
        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        await viewModel.setTitle("Dinner with mom in a week at 14 /rodina")

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

    @Test func testViewModel_naturalLanguageTitle_fuzzyMatchesMisspelledCalendarWord() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "family", title: "Přátelé a rodina", color: .systemPink),
            .make(id: "work", title: "Work", color: .systemBlue),
        ]
        let viewModel = makeViewModel(calendarService: calendarService)

        await viewModel.setTitle("Dinner with mom /rodna")

        #expect(viewModel.selectedCalendarId == "family")
        #expect(viewModel.matchedCalendarTitle == "Přátelé a rodina")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
    }

    @Test func testViewModel_naturalLanguageTitle_removingCalendarInstructionRestoresDefault() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "family", title: "Přátelé a rodina", color: .systemPink),
            .make(id: "work", title: "Work", color: .systemBlue),
        ]
        calendarService.m_defaultCalendarId = "work"
        let viewModel = makeViewModel(calendarService: calendarService)

        await viewModel.setTitle("Dinner with mom /rodina")
        #expect(viewModel.selectedCalendarId == "family")

        await viewModel.setTitle("Dinner with mom")

        #expect(viewModel.selectedCalendarId == "work")
        #expect(viewModel.matchedCalendarTitle == nil)
    }

    @Test func testViewModel_naturalLanguageTitle_usesSelectedTimeZone() async {

        let timeZone = TimeZone(identifier: "America/New_York")!
        let dateProvider = MockDateProvider(
            calendar: .gregorian.with(timeZone: timeZone),
            now: .make(year: 2025, month: 10, day: 25, hour: 10, timeZone: timeZone)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.setTitle("Dinner with mom tomorrow at 14:00")

        #expect(viewModel.title == "Dinner with mom tomorrow at 14:00")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14, timeZone: timeZone))
    }

    @Test func testViewModel_naturalLanguageTitle_leavesOrdinaryTitleUntouched() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner with mom")

        #expect(viewModel.title == "Dinner with mom")
        #expect(viewModel.parsedEventTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
    }

    @Test(arguments: ["from 14 to 16", "at 14 until 16"])
    func testViewModel_naturalLanguageTitle_endTimeRangeSetsStartAndEnd(_ instruction: String) async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Workshop tomorrow \(instruction)")

        #expect(viewModel.parsedEventTitle == "Workshop")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 16))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_endTimeRangeCanCrossMidnight() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Deployment tomorrow from 22 to 1")

        #expect(viewModel.parsedEventTitle == "Deployment")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 22))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 27, hour: 1))
    }

    @Test func testViewModel_naturalLanguageTitle_removingEndTimeRestoresOriginalDuration() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Workshop from 14 to 18")
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 18))

        await viewModel.setTitle("Workshop at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesNoonAndMidnight() async {

        let noonViewModel = makeViewModel()
        await noonViewModel.setTitle("Lunch tomorrow at noon")

        #expect(noonViewModel.parsedEventTitle == "Lunch")
        #expect(noonViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 12))

        let midnightViewModel = makeViewModel()
        await midnightViewModel.setTitle("Deployment tomorrow at midnight")

        #expect(midnightViewModel.parsedEventTitle == "Deployment")
        #expect(midnightViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 0))
        #expect(midnightViewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 1))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesMorningAndEvening() async {

        let morningViewModel = makeViewModel()
        await morningViewModel.setTitle("Coffee tomorrow morning")

        #expect(morningViewModel.parsedEventTitle == "Coffee")
        #expect(morningViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 9))

        let eveningViewModel = makeViewModel()
        await eveningViewModel.setTitle("Dinner tomorrow in the evening")

        #expect(eveningViewModel.parsedEventTitle == "Dinner")
        #expect(eveningViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 18))
    }

    @Test func testViewModel_naturalLanguageTitle_linkedDayPeriodAfterTitleStillParses() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Conference tomorrow morning")

        #expect(viewModel.parsedEventTitle == "Conference")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 9))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_eveningCanQualifyNumericTime() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Dinner tomorrow at 7 in the evening")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 19))
    }

    @Test func testViewModel_naturalLanguageTitle_relativeStartUsesCurrentTime() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Call in 2 hours")

        #expect(viewModel.parsedEventTitle == "Call")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 13, minute: 00))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 14, minute: 00))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_removingRelativeStartRestoresInitialDateAndTime() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Call in 2 hours")
        await viewModel.setTitle("Call")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_namedMonthDate() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Birthday on August 12 at noon")

        #expect(viewModel.parsedEventTitle == "Birthday")
        #expect(viewModel.startDate == .make(year: 2025, month: 8, day: 12, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_namedDayMonthDateWithYear() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Conference 12 August 2027 at 9")

        #expect(viewModel.parsedEventTitle == "Conference")
        #expect(viewModel.startDate == .make(year: 2027, month: 8, day: 12, hour: 9))
    }

    @Test func testViewModel_naturalLanguageTitle_namedDateUsesEnglishWithNonEnglishLocale() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.setTitle("Dinner 12 August at 14")

        #expect(viewModel.parsedEventTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 12, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_doesNotRecognizeLocalizedMonthNames() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(startDate: dateProvider.now, dateProvider: dateProvider)

        await viewModel.setTitle("Dinner 12 srpna at 14")

        #expect(viewModel.parsedEventTitle == "Dinner 12 srpna")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 6, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_removingNamedDateRestoresOriginalDate() async {

        let viewModel = makeViewModel()

        await viewModel.setTitle("Birthday on August 12 at noon")
        await viewModel.setTitle("Birthday at noon")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 12))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 13))
    }

    @Test func testViewModel_naturalLanguageTitle_neverParsesFirstWordAsInstruction() async {

        for title in [
            "Tomorrow planning",
            "August 12 birthday",
            "At 14 lunch",
            "In 2 hours call",
            "Full day workshop",
            "For 2 hours lecture",
            "Tomorrow morning conference",
        ] {
            let viewModel = makeViewModel()

            await viewModel.setTitle(title)

            #expect(viewModel.parsedEventTitle == title)
            #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
            #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
            #expect(viewModel.titleHighlights.isEmpty)
        }
    }

    @Test func testViewModel_naturalLanguageTitle_whenDisabledTreatsEntireInputAsTitle() {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "work", title: "Work"),
            .make(id: "personal", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "personal"
        let viewModel = makeViewModel(
            calendarService: calendarService,
            naturalLanguageEventInputEnabled: false
        )
        let title = "Dinner tomorrow next Monday at 14 full day for 3 hours /work"

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.title = title

        #expect(viewModel.parsedEventTitle == title)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
        #expect(viewModel.isAllDay == false)
        #expect(viewModel.selectedCalendarId == "personal")
        #expect(viewModel.matchedCalendarTitle == nil)
        #expect(viewModel.titleHighlights.isEmpty)
        #expect(viewModel.hasValidInput)

        viewModel.saveEvent()

        #expect(lastValue?.title == title)
        #expect(lastValue?.calendar == "personal")
    }

    @Test func testViewModel_dateRange_timed_endEqualStart_invalid() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        await viewModel.setTitle("Meeting")
        viewModel.endDate = viewModel.startDate

        #expect(viewModel.hasValidDateRange == false)
        #expect(viewModel.hasValidInput == false)
    }

    @Test func testViewModel_dateRange_timed_endAfterStart_valid() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(
            startDate: .make(year: 2025, month: 10, day: 25, hour: 10, minute: 30),
            calendarService: calendarService
        )

        await viewModel.setTitle("Meeting")
        viewModel.endDate = .make(year: 2025, month: 10, day: 25, hour: 13, minute: 0)

        #expect(viewModel.hasValidDateRange)
        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_dateRange_allDay_sameDay_valid() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        await viewModel.setTitle("Holiday")
        viewModel.isAllDay = true
        viewModel.startDate = .make(year: 2025, month: 10, day: 25, at: .start)
        viewModel.endDate = .make(year: 2025, month: 10, day: 25, at: .start)

        #expect(viewModel.hasValidDateRange)
        #expect(viewModel.hasValidInput)
    }

    @Test func testViewModel_dateRange_allDay_endBeforeStart_invalid() async{

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        await viewModel.setTitle("Holiday")
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

    @Test func testViewModel_saveEvent_withInvalidInput_shouldNotCallService() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        viewModel.saveEvent()
        #expect(lastValue == nil)

        await viewModel.setTitle("Meeting")
        viewModel.endDate = viewModel.startDate
        viewModel.saveEvent()
        #expect(lastValue == nil)
    }

    @Test func testViewModel_saveEvent_withValidInput() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let start: Date = .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0)
        let end: Date = .make(year: 2025, month: 10, day: 25, hour: 12, minute: 30)

        let viewModel = makeViewModel(startDate: start, calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        await viewModel.setTitle("  Team sync  ")
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

    @Test func testViewModel_saveEvent_passesSelectedTimeZone() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        await viewModel.setTitle("Meeting")
        viewModel.selectedTimeZoneIdentifier = "America/Sao_Paulo"
        viewModel.saveEvent()

        #expect(lastValue?.timeZone.identifier == "America/Sao_Paulo")
    }

    @Test func testViewModel_changingTimeZone_preservesWallClockTime() {

        let oldTimeZone = TimeZone(secondsFromGMT: 3 * 3600)!
        dateProvider.m_calendar = Calendar.gregorian.with(timeZone: oldTimeZone)

        let start: Date = .make(year: 2025, month: 10, day: 25, hour: 15, minute: 00, timeZone: oldTimeZone)

        let viewModel = makeViewModel(startDate: start)

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0, timeZone: oldTimeZone))

        viewModel.selectedTimeZoneIdentifier = "UTC"

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 15, minute: 0, timeZone: .utc))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 16, minute: 0, timeZone: .utc))
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

    @Test func testViewModel_saveEvent_withNoAlertSelected() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        await viewModel.setTitle("Meeting")
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == nil)
    }

    @Test func testViewModel_saveEvent_withAlertSelected() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        await viewModel.setTitle("Meeting")
        viewModel.selectedAlert = .tenMinutesBefore
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == -600)
    }

    @Test func testViewModel_saveEvent_withAtTimeOfEventAlert() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [.make(id: "cal-1")]

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        await viewModel.setTitle("Meeting")
        viewModel.selectedAlert = .atTimeOfEvent
        viewModel.saveEvent()

        #expect(lastValue?.alertOffset == 0)
    }

    @Test func testViewModel_saveEvent_withError() async {

        let calendarService = FailingEventCalendarService()
        calendarService.m_calendars = [.make()]

        let viewModel = makeViewModel(calendarService: calendarService)

        await viewModel.setTitle("Meeting")
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
        await viewModel.setTitle("Meeting")
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
        await viewModel.setTitle("Meeting")
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
        await viewModel.setTitle("Meeting")

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
        await viewModel.setTitle("Meeting")
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
        await viewModel.setTitle("   ")
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

    @Test func testViewModel_saveEvent_shouldPassSelectedCalendar() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "cal-1", title: "Work"),
            .make(id: "cal-2", title: "Personal"),
        ]
        calendarService.m_defaultCalendarId = "cal-1"

        let viewModel = makeViewModel(calendarService: calendarService)

        var lastValue: CreateEventArgs?
        _ = calendarService.spyCreateEventObservable.bind { lastValue = $0 }

        await viewModel.setTitle("Meeting")
        viewModel.selectedCalendarId = "cal-2"
        viewModel.saveEvent()

        #expect(lastValue?.calendar == "cal-2")
    }

    // MARK: - Factory

    func makeViewModel(
        startDate: Date? = nil,
        dateProvider: DateProviding? = nil,
        calendarService: CalendarServiceProviding = MockCalendarServiceProvider(),
        naturalLanguageEventInputEnabled: Bool = true,
        naturalLanguageEventInputLanguage: EventTitleParserLanguage = .english
    ) -> EventEditorViewModel {
        EventEditorViewModel(
            startDate: startDate ?? self.dateProvider.now,
            dateProvider: dateProvider ?? self.dateProvider,
            calendarService: calendarService,
            settings: MockEventEditorSettings(
                naturalLanguage: naturalLanguageEventInputEnabled,
                language: naturalLanguageEventInputLanguage
            ),
            scheduler: CurrentThreadScheduler.instance
        )
    }
}

private extension EventEditorViewModel {

    func setTitle(_ text: String, sourceLocation: SourceLocation = #_sourceLocation) async {
        let expectation = expectation(description: "Parsed", sourceLocation: sourceLocation)
        parseTitleFinished = expectation.fulfill
        title = text
        await fulfillment(of: [expectation])
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
