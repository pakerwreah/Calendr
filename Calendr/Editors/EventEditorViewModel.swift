//
//  EventEditorViewModel.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import AppKit
import Observation
import RxSwift

@Observation.Observable
class EventEditorViewModel: HostingWindowControllerDelegate {

    var title = "" {
        didSet {
            parseTitleInstructions()
        }
    }
    var startDate: Date {
        didSet {
            guard !isSyncingDates, startDate != oldValue else { return }
            isSyncingDates = true
            defer { isSyncingDates = false }

            if isAllDay {
                guard calendar.isDate(endDate, lessThan: startDate, granularity: .day) else { return }
                endDate = startDate
            } else {
                endDate = startDate.addingTimeInterval(eventDuration)
            }
        }
    }
    var endDate: Date {
        didSet {
            guard !isSyncingDates, endDate != oldValue, !isAllDay else { return }
            guard endDate > startDate else { return }
            eventDuration = endDate.timeIntervalSince(startDate)
        }
    }
    var isAllDay = false {
        didSet {
            guard isAllDay != oldValue else { return }
            adjustDatesForAllDayChange()
        }
    }
    var location = ""
    var url = ""
    var notes = ""
    var selectedAlert: EventAlert = .none
    var selectedTimeZoneIdentifier: String {
        didSet {
            guard selectedTimeZoneIdentifier != oldValue else { return }
            preserveWallClockTime(
                from: TimeZone(identifier: oldValue) ?? dateProvider.calendar.timeZone
            )
        }
    }
    var isCloseConfirmationVisible = false
    var isErrorVisible = false

    private(set) var calendarSections: [CalendarSection] = []
    var selectedCalendarId: String?
    private(set) var matchedCalendarTitle: String?
    private(set) var titleHighlights: [EventTitleHighlight] = []

    var selectedCalendarColor: NSColor {
        calendarSections
            .flatMap(\.calendars)
            .first { $0.id == selectedCalendarId }?
            .color ?? .clear
    }

    private(set) var error: UnexpectedError? {
        didSet {
            if error != nil {
                isErrorVisible = true
            }
        }
    }

    private let calendarService: CalendarServiceProviding
    private let dateProvider: DateProviding
    private let naturalLanguageEventInputEnabled: Bool
    private let naturalLanguageEventInputLanguage: EventTitleParserLanguage
    private let scheduler: ImmediateSchedulerType

    private let disposeBag = DisposeBag()

    private var eventDuration: TimeInterval
    private var isSyncingDates = false
    private var parsedTitle: EventTitleParseResult = .empty()
    private var defaultCalendarId: String?
    private var hasCalendarInstruction = false
    private var parserAllDayRestoreState: ParserAllDayRestoreState?
    private var parserDurationRestoreState: ParserDurationRestoreState?
    private var parserEndTimeRestoreDuration: TimeInterval?
    private var parserDateRestoreComponents: DateComponents?
    private var parserTimeRestoreState: ParserTimeRestoreState?

    private var calendar: Calendar { dateProvider.calendar.with(timeZone: selectedTimeZone) }

    var selectedTimeZone: TimeZone {
        TimeZone(identifier: selectedTimeZoneIdentifier) ?? dateProvider.calendar.timeZone
    }

    init(
        startDate: Date,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        settings: EventEditorSettings,
        scheduler: ImmediateSchedulerType
    ) {
        self.dateProvider = dateProvider
        let defaultDuration: TimeInterval = 3600
        self.startDate = startDate
        self.eventDuration = defaultDuration
        self.endDate = startDate.addingTimeInterval(defaultDuration)
        self.calendarService = calendarService
        self.naturalLanguageEventInputEnabled = settings.naturalLanguageEventInputEnabled.lastValue() ?? false
        self.naturalLanguageEventInputLanguage = settings.naturalLanguageEventInputLanguage.lastValue() ?? .english
        self.scheduler = scheduler
        self.selectedTimeZoneIdentifier = dateProvider.calendar.timeZone.identifier

        loadCalendars()
    }

    var onCloseConfirmed: (() -> Void)?

    func confirmClose() {
        isCloseConfirmationVisible = false
        onCloseConfirmed?()
    }

    func dismissError() {
        isErrorVisible = false
        error = nil
    }

    var parsedUrl: URL? {
        let trimmed = url.trimmed
        guard !trimmed.isEmpty else { return nil }
        return URL(string: trimmed)
    }

    var hasValidDateRange: Bool {
        if isAllDay {
            return calendar.isDate(endDate, greaterThanOrEqualTo: startDate, granularity: .day)
        }
        return endDate > startDate
    }

    var hasValidInput: Bool {
        parsedEventTitle.isNotBlank
            && hasValidDateRange
            && selectedCalendarId != nil
            && !hasConflicts
    }

    var parsedEventTitle: String {
        naturalLanguageEventInputEnabled ? parsedTitle.cleanedTitle : title.trimmed
    }

    var hasConflicts: Bool {
        naturalLanguageEventInputEnabled && parsedTitle.hasConflicts
    }

    var hasUnsavedChanges: Bool {
        [title, location, url, notes].contains(where: \.isNotBlank)
    }

    func saveEvent() {
        guard hasValidInput, let selectedCalendarId else { return }

        calendarService.createEvent(
            title: parsedEventTitle,
            calendar: selectedCalendarId,
            start: startDate,
            end: endDate,
            isAllDay: isAllDay,
            location: location.trimmed.notEmpty,
            url: parsedUrl,
            notes: notes.trimmed.notEmpty,
            alertOffset: selectedAlert.relativeOffset,
            timeZone: selectedTimeZone
        )
        .observe(on: scheduler)
        .subscribe(onCompleted: { [weak self] in
            self?.confirmClose()
        }, onError: { [weak self] error in
            self?.error = error.unexpected
        })
        .disposed(by: disposeBag)
    }

    func requestWindowClose() -> Bool {
        if hasUnsavedChanges {
            isCloseConfirmationVisible = true
        }
        return !isCloseConfirmationVisible
    }

    // MARK: - Private

    private func preserveWallClockTime(from oldTimeZone: TimeZone) {
        let newTimeZone = selectedTimeZone
        guard oldTimeZone != newTimeZone else { return }
        isSyncingDates = true
        defer { isSyncingDates = false }

        let oldCalendar = dateProvider.calendar.with(timeZone: oldTimeZone)
        let newCalendar = dateProvider.calendar.with(timeZone: newTimeZone)

        let components: Set<Calendar.Component> = isAllDay
            ? [.year, .month, .day]
            : [.year, .month, .day, .hour, .minute, .second]

        let startComponents = oldCalendar.dateComponents(components, from: startDate)
        let endComponents = oldCalendar.dateComponents(components, from: endDate)

        startDate = newCalendar.date(from: startComponents) ?? startDate
        endDate = newCalendar.date(from: endComponents) ?? endDate
    }

    private func adjustDatesForAllDayChange() {
        isSyncingDates = true
        defer { isSyncingDates = false }

        if isAllDay {
            startDate = calendar.startOfDay(for: startDate)
            endDate = calendar.startOfDay(for: endDate)
            if calendar.isDate(endDate, lessThan: startDate, granularity: .day) {
                endDate = startDate
            }
        } else if endDate <= startDate {
            endDate = startDate.addingTimeInterval(eventDuration)
        }
    }

    private func parseTitleInstructions() {
        guard naturalLanguageEventInputEnabled else { return }

        let previousParsedTitle = parsedTitle
        let newParsedTitle = EventTitleParser.parse(
            title,
            calendar: calendar,
            referenceDate: dateProvider.now,
            language: naturalLanguageEventInputLanguage
        )

        if previousParsedTitle.duration != nil, newParsedTitle.duration == nil {
            restoreParsedDuration()
        }
        if previousParsedTitle.endTime != nil, newParsedTitle.endTime == nil {
            restoreParsedEndTime()
        }
        if previousParsedTitle.isAllDay, !newParsedTitle.isAllDay {
            restoreParsedAllDay(durationRemains: newParsedTitle.duration != nil)
        }
        if hasDateInstruction(previousParsedTitle), !hasDateInstruction(newParsedTitle) {
            restoreParsedDate()
        }
        if hasTimeInstruction(previousParsedTitle), !hasTimeInstruction(newParsedTitle) {
            restoreParsedTime()
        }

        if !hasDateInstruction(previousParsedTitle), hasDateInstruction(newParsedTitle) {
            captureDateRestoreState()
        }
        if !hasTimeInstruction(previousParsedTitle), hasTimeInstruction(newParsedTitle) {
            captureTimeRestoreState()
        }
        if previousParsedTitle.endTime == nil, newParsedTitle.endTime != nil {
            parserEndTimeRestoreDuration = eventDuration
        }

        parsedTitle = newParsedTitle

        let matchedCalendar = parsedTitle.calendarQuery.flatMap(findCalendar)
        matchedCalendarTitle = matchedCalendar?.title
        if parsedTitle.calendarQuery != nil {
            hasCalendarInstruction = true
            if let matchedCalendar {
                selectedCalendarId = matchedCalendar.id
            }
        } else if hasCalendarInstruction {
            hasCalendarInstruction = false
            if let defaultCalendarId {
                selectedCalendarId = defaultCalendarId
            }
        }

        titleHighlights = parsedTitle.tokens.map { token in
            let color: NSColor
            switch token.kind {
            case .date: color = .systemBlue
            case .time: color = .systemOrange
            case .duration: color = .systemGreen
            case .allDay: color = .systemPurple
            case .calendar: color = matchedCalendar?.color ?? .systemGray
            }
            return .init(range: token.range, color: color)
        }

        applyParsedDateAndTime()
    }

    private func applyParsedDateAndTime() {
        if parsedTitle.isAllDay {
            if !isAllDay {
                captureAllDayRestoreState()
                isAllDay = true
            }
        } else if hasTimeInstruction(parsedTitle) {
            isAllDay = false
        }

        if let relativeStart = parsedTitle.relativeStart {
            let component: Calendar.Component = relativeStart.unit == .minute ? .minute : .hour
            startDate = calendar.date(
                byAdding: component,
                value: relativeStart.value,
                to: dateProvider.now
            ) ?? startDate
        } else if hasDateInstruction(parsedTitle) || parsedTitle.time != nil {
            let targetDay: Date
            if let dayOffset = parsedTitle.dayOffset {
                let today = calendar.startOfDay(for: dateProvider.now)
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { return }
                targetDay = date
            } else if let numericDate = parsedTitle.numericDate {
                guard let date = makeDate(from: numericDate) else { return }
                targetDay = date
            } else if let weekday = parsedTitle.weekday {
                guard let date = makeDate(from: weekday) else { return }
                targetDay = date
            } else {
                targetDay = calendar.startOfDay(for: startDate)
            }

            if parsedTitle.isAllDay {
                setAllDayStartDatePreservingSpan(targetDay)
            } else {
                let currentTime = calendar.dateComponents([.hour, .minute], from: startDate)
                let hour = parsedTitle.time?.hour ?? currentTime.hour ?? 0
                let minute = parsedTitle.time?.minute ?? currentTime.minute ?? 0

                guard let parsedStartDate = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: targetDay,
                    matchingPolicy: .nextTimePreservingSmallerComponents,
                    repeatedTimePolicy: .first,
                    direction: .forward
                ) else {
                    return
                }

                startDate = parsedStartDate
            }
        }

        applyParsedDuration()
        applyParsedEndTime()
    }

    private func makeDate(from numericDate: EventTitleNumericDate) -> Date? {
        let currentYear = calendar.component(.year, from: dateProvider.now)
        let components = DateComponents(
            year: numericDate.year ?? currentYear,
            month: numericDate.month,
            day: numericDate.day
        )
        guard let date = calendar.date(from: components) else { return nil }

        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        guard
            resolved.year == components.year,
            resolved.month == components.month,
            resolved.day == components.day
        else {
            return nil
        }
        return calendar.startOfDay(for: date)
    }

    private func makeDate(from weekday: EventTitleWeekday) -> Date? {
        let today = calendar.startOfDay(for: dateProvider.now)
        let currentWeekday = calendar.component(.weekday, from: today)
        var daysUntilWeekday = (weekday.weekday - currentWeekday + 7) % 7
        if weekday.occurrence == .following {
            daysUntilWeekday += 7
        }
        return calendar.date(byAdding: .day, value: daysUntilWeekday, to: today)
    }

    private func applyParsedDuration() {
        guard let duration = parsedTitle.duration else { return }

        if parserDurationRestoreState == nil {
            if isAllDay {
                let days = (calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: startDate),
                    to: calendar.startOfDay(for: endDate)
                ).day ?? 0) + 1
                parserDurationRestoreState = .allDay(days: max(1, days))
            } else {
                parserDurationRestoreState = .timed(eventDuration)
            }
        }

        if isAllDay {
            let days: Int
            switch duration.unit {
            case .day: days = duration.value
            case .week: days = duration.value * 7
            case .minute, .hour: return
            }
            endDate = calendar.date(byAdding: .day, value: days - 1, to: startDate) ?? endDate
            return
        }

        let component: Calendar.Component
        let value: Int
        switch duration.unit {
        case .minute:
            component = .minute
            value = duration.value
        case .hour:
            component = .hour
            value = duration.value
        case .day:
            component = .day
            value = duration.value
        case .week:
            component = .day
            value = duration.value * 7
        }
        endDate = calendar.date(byAdding: component, value: value, to: startDate) ?? endDate
    }

    private func applyParsedEndTime() {
        guard !isAllDay, let endTime = parsedTitle.endTime else { return }

        let startDay = calendar.startOfDay(for: startDate)
        guard var parsedEndDate = calendar.date(
            bySettingHour: endTime.hour,
            minute: endTime.minute,
            second: 0,
            of: startDay,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            repeatedTimePolicy: .first,
            direction: .forward
        ) else {
            return
        }

        if parsedEndDate <= startDate {
            parsedEndDate = calendar.date(byAdding: .day, value: 1, to: parsedEndDate) ?? parsedEndDate
        }
        endDate = parsedEndDate
    }

    private func captureAllDayRestoreState() {
        let time = calendar.dateComponents([.hour, .minute], from: startDate)
        let duration: TimeInterval
        if case let .timed(originalDuration)? = parserDurationRestoreState {
            duration = originalDuration
        } else {
            duration = eventDuration
        }
        parserAllDayRestoreState = .init(
            hour: time.hour ?? 0,
            minute: time.minute ?? 0,
            duration: duration
        )
    }

    private func restoreParsedDuration() {
        guard let restoreState = parserDurationRestoreState else { return }
        defer { parserDurationRestoreState = nil }

        switch restoreState {
        case let .timed(duration):
            if isAllDay {
                endDate = startDate
            } else {
                eventDuration = duration
                endDate = startDate.addingTimeInterval(duration)
            }
        case let .allDay(days):
            if isAllDay {
                endDate = calendar.date(byAdding: .day, value: days - 1, to: startDate) ?? startDate
            }
        }
    }

    private func restoreParsedEndTime() {
        guard let duration = parserEndTimeRestoreDuration else { return }
        defer { parserEndTimeRestoreDuration = nil }

        eventDuration = duration
        if !isAllDay {
            endDate = startDate.addingTimeInterval(duration)
        }
    }

    private func restoreParsedAllDay(durationRemains: Bool) {
        guard let restoreState = parserAllDayRestoreState else { return }
        defer { parserAllDayRestoreState = nil }

        if durationRemains, case .allDay? = parserDurationRestoreState {
            parserDurationRestoreState = .timed(restoreState.duration)
        }

        isAllDay = false
        eventDuration = restoreState.duration

        let day = calendar.startOfDay(for: startDate)
        guard let restoredStartDate = calendar.date(
            bySettingHour: restoreState.hour,
            minute: restoreState.minute,
            second: 0,
            of: day,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            repeatedTimePolicy: .first,
            direction: .forward
        ) else {
            return
        }
        startDate = restoredStartDate
    }

    private func captureDateRestoreState() {
        parserDateRestoreComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
    }

    private func restoreParsedDate() {
        guard
            let components = parserDateRestoreComponents,
            let restoredDay = calendar.date(from: components)
        else {
            return
        }
        defer { parserDateRestoreComponents = nil }

        if isAllDay {
            setAllDayStartDatePreservingSpan(restoredDay)
            return
        }

        let time = calendar.dateComponents([.hour, .minute], from: startDate)
        guard let restoredStartDate = calendar.date(
            bySettingHour: time.hour ?? 0,
            minute: time.minute ?? 0,
            second: 0,
            of: restoredDay,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            repeatedTimePolicy: .first,
            direction: .forward
        ) else {
            return
        }
        startDate = restoredStartDate
    }

    private func captureTimeRestoreState() {
        if isAllDay, let allDayState = parserAllDayRestoreState {
            parserTimeRestoreState = .init(hour: allDayState.hour, minute: allDayState.minute)
            return
        }
        let time = calendar.dateComponents([.hour, .minute], from: startDate)
        parserTimeRestoreState = .init(hour: time.hour ?? 0, minute: time.minute ?? 0)
    }

    private func restoreParsedTime() {
        guard let restoreState = parserTimeRestoreState else { return }
        defer { parserTimeRestoreState = nil }

        if isAllDay {
            if let allDayState = parserAllDayRestoreState {
                parserAllDayRestoreState = .init(
                    hour: restoreState.hour,
                    minute: restoreState.minute,
                    duration: allDayState.duration
                )
            }
            return
        }

        let day = calendar.startOfDay(for: startDate)
        guard let restoredStartDate = calendar.date(
            bySettingHour: restoreState.hour,
            minute: restoreState.minute,
            second: 0,
            of: day,
            matchingPolicy: .nextTimePreservingSmallerComponents,
            repeatedTimePolicy: .first,
            direction: .forward
        ) else {
            return
        }
        startDate = restoredStartDate
    }

    private func setAllDayStartDatePreservingSpan(_ date: Date) {
        let startDay = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)
        let days = max(1, (calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0) + 1)

        isSyncingDates = true
        defer { isSyncingDates = false }
        startDate = calendar.startOfDay(for: date)
        endDate = calendar.date(byAdding: .day, value: days - 1, to: startDate) ?? startDate
    }

    private func hasDateInstruction(_ result: EventTitleParseResult) -> Bool {
        result.dayOffset != nil
            || result.numericDate != nil
            || result.weekday != nil
            || result.relativeStart != nil
    }

    private func hasTimeInstruction(_ result: EventTitleParseResult) -> Bool {
        result.time != nil || result.relativeStart != nil
    }

    private func findCalendar(matching query: String) -> CalendarModel? {
        calendarSections
            .flatMap(\.calendars)
            .compactMap { calendar in
                fuzzyScore(query: query, candidate: calendar.title).map { (calendar, $0) }
            }
            .min {
                if $0.1 == $1.1 {
                    return $0.0.title.localizedCaseInsensitiveCompare($1.0.title) == .orderedAscending
                }
                return $0.1 < $1.1
            }?
            .0
    }

    private func loadCalendars() {

        calendarService.calendars(forNew: .event)
            .observe(on: scheduler)
            .subscribe(onSuccess: { [weak self] calendars in
                self?.setupCalendars(calendars)
            }, onFailure: { [weak self] error in
                self?.error = error.unexpected
            })
            .disposed(by: disposeBag)
    }

    private func setupCalendars(_ calendars: [CalendarModel]) {

        calendarSections = calendars.groupedByAccount()

        let defaultId = calendarService.defaultCalendar(forNew: .event)?.id

        if let defaultId, calendars.contains(where: { $0.id == defaultId }) {
            defaultCalendarId = defaultId
        } else if let first = calendarSections.first?.calendars.first {
            defaultCalendarId = first.id
        }
        selectedCalendarId = defaultCalendarId

        parseTitleInstructions()
    }
}

private struct ParserAllDayRestoreState {
    let hour: Int
    let minute: Int
    let duration: TimeInterval
}

private struct ParserTimeRestoreState {
    let hour: Int
    let minute: Int
}

private enum ParserDurationRestoreState {
    case timed(TimeInterval)
    case allDay(days: Int)
}

private func fuzzyScore(query: String, candidate: String) -> Int? {
    let query = normalized(query)
    let candidate = normalized(candidate)
    guard !query.isEmpty else { return nil }

    if query == candidate { return 0 }
    if let range = candidate.range(of: query) {
        return 10 + candidate.distance(from: candidate.startIndex, to: range.lowerBound)
    }

    let words = candidate.split(separator: " ").map(String.init)
    if let prefix = words.first(where: { $0.hasPrefix(query) }) {
        return 30 + prefix.count - query.count
    }

    guard query.count >= 3 else { return nil }
    let distance = ([candidate] + words).map { editDistance(query, $0) }.min() ?? .max
    guard distance <= max(1, query.count / 3) else { return nil }
    return 100 + distance
}

private func normalized(_ value: String) -> String {
    value
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        .lowercased()
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func editDistance(_ lhs: String, _ rhs: String) -> Int {
    let lhs = Array(lhs)
    let rhs = Array(rhs)
    var previous = Array(0...rhs.count)

    for (lhsIndex, lhsCharacter) in lhs.enumerated() {
        var current = [lhsIndex + 1]
        for (rhsIndex, rhsCharacter) in rhs.enumerated() {
            current.append(min(
                current[rhsIndex] + 1,
                previous[rhsIndex + 1] + 1,
                previous[rhsIndex] + (lhsCharacter == rhsCharacter ? 0 : 1)
            ))
        }
        previous = current
    }

    return previous[rhs.count]
}
