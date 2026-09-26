//
//  EventEditorViewModelNaturalLanguageTests.swift
//  Calendr
//
//  Created by Paker on 26/09/2026.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventEditorViewModelNaturalLanguageTests {

    let dateProvider = MockDateProvider(
        now: .make(year: 2025, month: 10, day: 25, hour: 11, minute: 0)
    )

    @Test(arguments: ["14", "2pm", "14:00"])
    func testViewModel_naturalLanguageTitle_setsTomorrowAtTwoPM(_ time: String) async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner with mom tomorrow at \(time)")

        #expect(viewModel.title == "Dinner with mom tomorrow at \(time)")
        #expect(viewModel.cleanTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 15))
        #expect(viewModel.titleHighlights.count == 2)
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesDateBeforeTimeIsEntered() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner with mom in a week")

        #expect(viewModel.cleanTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 11))

        await viewModel.parseTitle("\(viewModel.title) at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesYesterday() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Retrospective yesterday")

        #expect(viewModel.cleanTitle == "Retrospective")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 24, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesInNumberOfDays() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Call in 3 days")

        #expect(viewModel.cleanTitle == "Call")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 28, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesTimeWithoutDate() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner at 14")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_fullDayChecksAllDay() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Holiday in a week full day")

        #expect(viewModel.cleanTitle == "Holiday")
        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 11, day: 1, at: .start))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemPurple])
    }

    @Test func testViewModel_naturalLanguageTitle_durationSetsEndTime() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner tomorrow at 14 for 2 hours")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 16))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange, .systemGreen])
    }

    @Test func testViewModel_naturalLanguageTitle_durationSupportsSingularDay() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Retreat for 4 day")

        #expect(viewModel.cleanTitle == "Retreat")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_allDayDurationUsesInclusiveEndDate() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Retreat tomorrow full day for 4 days")

        #expect(viewModel.cleanTitle == "Retreat")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_removingFullDayRestoresTimedState() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Holiday tomorrow full day")
        #expect(viewModel.isAllDay)

        await viewModel.parseTitle("Holiday tomorrow")

        #expect(viewModel.isAllDay == false)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDurationRestoresPreviousDuration() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner tomorrow at 14 for 4 hours")
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 18))

        await viewModel.parseTitle("Dinner tomorrow at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_removingAllDayDurationRestoresOneDay() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Holiday tomorrow full day for 4 days")
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 29, at: .start))

        await viewModel.parseTitle("Holiday tomorrow full day")

        #expect(viewModel.isAllDay)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, at: .start))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, at: .start))
    }

    @Test func testViewModel_naturalLanguageTitle_removingAllDayAndDurationRestoresTimedState() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Holiday tomorrow full day for 4 days")

        await viewModel.parseTitle("Holiday tomorrow")

        #expect(viewModel.isAllDay == false)
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateRestoresOriginalDate() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner tomorrow at 14")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))

        await viewModel.parseTitle("Dinner at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_removingTimeRestoresOriginalTime() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner tomorrow at 14")

        await viewModel.parseTitle("Dinner tomorrow")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateAndTimeRestoresInitialState() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner tomorrow at 14")

        await viewModel.parseTitle("Dinner")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_removingTimeKeepsParsedDuration() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner tomorrow at 14 for 2 hours")

        await viewModel.parseTitle("Dinner tomorrow for 2 hours")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 13))
    }

    @Test func testViewModel_naturalLanguageTitle_removingWeekdayRestoresOriginalDate() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner next Saturday")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 11))

        await viewModel.parseTitle("Dinner")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
    }

    @Test func testViewModel_naturalLanguageTitle_removingDateFromAllDayRestoresOriginalDay() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Holiday tomorrow full day")

        await viewModel.parseTitle("Holiday full day")

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
        let viewModel = makeViewModel(
            startDate: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 25),
            dateProvider: dateProvider
        )

        await viewModel.parseTitle("Dinner 7.8.")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 7, hour: 10, minute: 25))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesMonthFirstLocale() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "en_US"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(
            startDate: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 25),
            dateProvider: dateProvider
        )

        await viewModel.parseTitle("Dinner 7.8.")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 7, day: 8, hour: 10, minute: 25))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesDayFirstLocale_withTimeOverlap() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.parseTitle("Dinner at 7.8.")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 7, hour: 7))
    }

    @Test func testViewModel_naturalLanguageTitle_numericDateUsesMonthFirstLocale_withTimeOverlap() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "en_US"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.parseTitle("Dinner at 7.8.")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 7, day: 8, hour: 7))
    }

    @Test func testViewModel_naturalLanguageTitle_onWeekdayUsesNearestOccurrence() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner on Saturday at 14")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_atWeekdayUsesNearestOccurrence() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner with mom at friday")

        #expect(viewModel.cleanTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 31, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 31, hour: 12))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue])
    }

    @Test func testViewModel_naturalLanguageTitle_atWeekdayWithTimeRange() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner with mom at friday from 12 to 23")

        #expect(viewModel.cleanTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 31, hour: 12))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 31, hour: 23))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_nextWeekdayUsesFollowingOccurrence() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner next Saturday at 14")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 11, day: 1, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_fuzzyMatchesMisspelledWeekday() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner on satruday at 14")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_supportsWeekdayAbbreviation() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Brunch on Sun")

        #expect(viewModel.cleanTitle == "Brunch")
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

        await viewModel.parseTitle("Dinner with mom in a week at 14 /rodina")

        #expect(viewModel.title == "Dinner with mom in a week at 14 /rodina")
        #expect(viewModel.cleanTitle == "Dinner with mom")
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

        await viewModel.parseTitle("Dinner with mom /rodna")

        #expect(viewModel.selectedCalendarId == "family")
        #expect(viewModel.matchedCalendarTitle == "Přátelé a rodina")
        #expect(viewModel.cleanTitle == "Dinner with mom")
    }

    @Test func testViewModel_naturalLanguageTitle_removingCalendarInstructionRestoresDefault() async {

        let calendarService = MockCalendarServiceProvider()
        calendarService.m_calendars = [
            .make(id: "family", title: "Přátelé a rodina", color: .systemPink),
            .make(id: "work", title: "Work", color: .systemBlue),
        ]
        calendarService.m_defaultCalendarId = "work"
        let viewModel = makeViewModel(calendarService: calendarService)

        await viewModel.parseTitle("Dinner with mom /rodina")
        #expect(viewModel.selectedCalendarId == "family")

        await viewModel.parseTitle("Dinner with mom")

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

        await viewModel.parseTitle("Dinner with mom tomorrow at 14:00")

        #expect(viewModel.title == "Dinner with mom tomorrow at 14:00")
        #expect(viewModel.cleanTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14, timeZone: timeZone))
    }

    @Test func testViewModel_naturalLanguageTitle_leavesOrdinaryTitleUntouched() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner with mom")

        #expect(viewModel.title == "Dinner with mom")
        #expect(viewModel.cleanTitle == "Dinner with mom")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
    }

    @Test(arguments: ["from 14 to 16", "at 14 until 16"])
    func testViewModel_naturalLanguageTitle_endTimeRangeSetsStartAndEnd(_ instruction: String) async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Workshop tomorrow \(instruction)")

        #expect(viewModel.cleanTitle == "Workshop")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 16))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_endTimeRangeCanCrossMidnight() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Deployment tomorrow from 22 to 1")

        #expect(viewModel.cleanTitle == "Deployment")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 22))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 27, hour: 1))
    }

    @Test func testViewModel_naturalLanguageTitle_removingEndTimeRestoresOriginalDuration() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Workshop from 14 to 18")
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 18))

        await viewModel.parseTitle("Workshop at 14")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 14))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 15))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesNoonAndMidnight() async {

        let noonViewModel = makeViewModel()
        await noonViewModel.parseTitle("Lunch tomorrow at noon")

        #expect(noonViewModel.cleanTitle == "Lunch")
        #expect(noonViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 12))

        let midnightViewModel = makeViewModel()
        await midnightViewModel.parseTitle("Deployment tomorrow at midnight")

        #expect(midnightViewModel.cleanTitle == "Deployment")
        #expect(midnightViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 0))
        #expect(midnightViewModel.endDate == .make(year: 2025, month: 10, day: 26, hour: 1))
    }

    @Test func testViewModel_naturalLanguageTitle_recognizesMorningAndEvening() async {

        let morningViewModel = makeViewModel()
        await morningViewModel.parseTitle("Coffee tomorrow morning")

        #expect(morningViewModel.cleanTitle == "Coffee")
        #expect(morningViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 9))

        let eveningViewModel = makeViewModel()
        await eveningViewModel.parseTitle("Dinner tomorrow in the evening")

        #expect(eveningViewModel.cleanTitle == "Dinner")
        #expect(eveningViewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 18))
    }

    @Test func testViewModel_naturalLanguageTitle_linkedDayPeriodAfterTitleStillParses() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Conference tomorrow morning")

        #expect(viewModel.cleanTitle == "Conference")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 9))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemBlue, .systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_eveningCanQualifyNumericTime() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Dinner tomorrow at 7 in the evening")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 26, hour: 19))
    }

    @Test func testViewModel_naturalLanguageTitle_relativeStartUsesCurrentTime() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Call in 2 hours")

        #expect(viewModel.cleanTitle == "Call")
        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 13, minute: 00))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 14, minute: 00))
        #expect(viewModel.titleHighlights.map(\.color) == [.systemOrange])
    }

    @Test func testViewModel_naturalLanguageTitle_removingRelativeStartRestoresInitialDateAndTime() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Call in 2 hours")
        await viewModel.parseTitle("Call")

        #expect(viewModel.startDate == .make(year: 2025, month: 10, day: 25, hour: 11))
        #expect(viewModel.endDate == .make(year: 2025, month: 10, day: 25, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_namedMonthDate() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Birthday on August 12 at noon")

        #expect(viewModel.cleanTitle == "Birthday")
        #expect(viewModel.startDate == .make(year: 2025, month: 8, day: 12, hour: 12))
    }

    @Test func testViewModel_naturalLanguageTitle_namedDayMonthDateWithYear() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Conference 12 August 2027 at 9")

        #expect(viewModel.cleanTitle == "Conference")
        #expect(viewModel.startDate == .make(year: 2027, month: 8, day: 12, hour: 9))
    }

    @Test func testViewModel_naturalLanguageTitle_namedDateUsesEnglishWithNonEnglishLocale() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(dateProvider: dateProvider)

        await viewModel.parseTitle("Dinner 12 August at 14")

        #expect(viewModel.cleanTitle == "Dinner")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 12, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_doesNotRecognizeLocalizedMonthNames() async {

        let calendar = Calendar.gregorian.with(locale: Locale(identifier: "cs_CZ"))
        let dateProvider = MockDateProvider(
            calendar: calendar,
            now: .make(year: 2026, month: 8, day: 6, hour: 10, minute: 30)
        )
        let viewModel = makeViewModel(
            startDate: dateProvider.now,
            dateProvider: dateProvider,
        )

        await viewModel.parseTitle("Dinner 12 srpna at 14")

        #expect(viewModel.cleanTitle == "Dinner 12 srpna")
        #expect(viewModel.startDate == .make(year: 2026, month: 8, day: 6, hour: 14))
    }

    @Test func testViewModel_naturalLanguageTitle_removingNamedDateRestoresOriginalDate() async {

        let viewModel = makeViewModel()

        await viewModel.parseTitle("Birthday on August 12 at noon")
        await viewModel.parseTitle("Birthday at noon")

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

            await viewModel.parseTitle(title)

            #expect(viewModel.cleanTitle == title)
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

        #expect(viewModel.cleanTitle == title)
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

    // MARK: - Factory

    func makeViewModel(
        startDate: Date? = nil,
        dateProvider: DateProviding? = nil,
        calendarService: CalendarServiceProviding = MockCalendarServiceProvider(),
        naturalLanguageEventInputEnabled: Bool = true,
    ) -> EventEditorViewModel {
        EventEditorViewModel(
            startDate: startDate ?? dateProvider?.now ?? self.dateProvider.now,
            dateProvider: dateProvider ?? self.dateProvider,
            calendarService: calendarService,
            settings: MockEventEditorSettings(
                naturalLanguage: naturalLanguageEventInputEnabled,
                language: .english
            ),
            scheduler: CurrentThreadScheduler.instance
        )
    }
}

private extension EventEditorViewModel {

    func parseTitle(_ text: String, sourceLocation: SourceLocation = #_sourceLocation) async {
        let expectation = expectation(description: "Parsed", sourceLocation: sourceLocation)
        parseTitleFinished = expectation.fulfill
        title = text
        await fulfillment(of: [expectation])
    }
}
