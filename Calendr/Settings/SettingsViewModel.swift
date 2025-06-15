//
//  SettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 16/01/21.
//

import Cocoa
import RxSwift

protocol StatusItemSettings {
    var showStatusItemIcon: Observable<Bool> { get }
    var showStatusItemDate: Observable<Bool> { get }
    var showStatusItemBackground: Observable<Bool> { get }
    var openOnHover: Observable<Bool> { get }
    var statusItemIconStyle: Observable<StatusItemIconStyle> { get }
    var statusItemDateStyle: Observable<StatusItemDateStyle> { get }
    var statusItemDateFormat: Observable<String> { get }
    var showEventStatusItem: Observable<Bool> { get }
    var statusItemTextScaling: Observable<Double> { get }
}

protocol CalendarSettings {
    var calendarScaling: Observable<Double> { get }
    var textScaling: Observable<Double> { get }
    var calendarTextScaling: Observable<Double> { get }
    var firstWeekday: Observable<Int> { get }
    var weekCount: Observable<Int> { get }
    var highlightedWeekdays: Observable<[Int]> { get }
    var showWeekNumbers: Observable<Bool> { get }
    var showDeclinedEvents: Observable<Bool> { get }
    var preserveSelectedDate: Observable<Bool> { get }
    var dateHoverOption: Observable<Bool> { get }
    var calendarAppViewMode: Observable<CalendarViewMode> { get }
    var defaultCalendarApp: Observable<CalendarApp> { get }
}

protocol AppearanceSettings {
    var appearanceMode: Observable<AppearanceMode> { get }
    var popoverMaterial: Observable<PopoverMaterial> { get }
    var textScaling: Observable<Double> { get }
}

protocol EventSettings: AppearanceSettings {
    var showRecurrenceIndicator: Observable<Bool> { get }
    var forceLocalTimeZone: Observable<Bool> { get }
    var showMap: Observable<Bool> { get }
}

protocol EventListSettings: EventSettings {
    var showPastEvents: Observable<Bool> { get }
    var showOverdueReminders: Observable<Bool> { get }
}

protocol NextEventSettings: EventSettings {
    var showEventStatusItem: Observable<Bool> { get }
    var eventStatusItemCheckRange: Observable<Int> { get }
    var eventStatusItemFlashing: Observable<Bool> { get }
    var eventStatusItemSound: Observable<Bool> { get }
    var eventStatusItemTextScaling: Observable<Double> { get }
    var eventStatusItemLength: Observable<Int> { get }
    var eventStatusItemDetectNotch: Observable<Bool> { get }
}

class SettingsViewModel:
    StatusItemSettings, NextEventSettings, CalendarSettings,
    EventListSettings, EventSettings, AppearanceSettings {

    struct IconStyleOption: Equatable {
        let style: StatusItemIconStyle
        let image: NSImage
        let title: String
    }

    struct DateFormatOption: Equatable {
        let style: StatusItemDateStyle
        let title: String
    }

    struct CalendarViewModeOption: Equatable {
        let mode: CalendarViewMode
        let title: String
    }

    struct CalendarAppOption: Equatable {
        let id: CalendarApp
        let icon: NSImage
        let name: String
    }

    // Observers
    let toggleAutoLaunch: AnyObserver<Bool>
    let toggleStatusItemIcon: AnyObserver<Bool>
    let toggleStatusItemDate: AnyObserver<Bool>
    let toggleStatusItemBackground: AnyObserver<Bool>
    let toggleOpenOnHover: AnyObserver<Bool>
    let statusItemTextScalingObserver: AnyObserver<Double>
    let statusItemIconStyleObserver: AnyObserver<StatusItemIconStyle>
    let statusItemDateStyleObserver: AnyObserver<StatusItemDateStyle>
    let statusItemDateFormatObserver: AnyObserver<String>
    let toggleEventStatusItem: AnyObserver<Bool>
    let eventStatusItemCheckRangeObserver: AnyObserver<Int>
    let toggleEventStatusItemFlashing: AnyObserver<Bool>
    let toggleEventStatusItemSound: AnyObserver<Bool>
    let eventStatusItemTextScalingObserver: AnyObserver<Double>
    let eventStatusItemLengthObserver: AnyObserver<Int>
    let toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    let calendarScalingObserver: AnyObserver<Double>
    let firstWeekdayPrevObserver: AnyObserver<Void>
    let firstWeekdayNextObserver: AnyObserver<Void>
    let weekCountObserver: AnyObserver<Int>
    let toggleHighlightedWeekday: AnyObserver<Int>
    let toggleWeekNumbers: AnyObserver<Bool>
    let toggleDeclinedEvents: AnyObserver<Bool>
    let togglePreserveSelectedDate: AnyObserver<Bool>
    let toggleDateHoverOption: AnyObserver<Bool>
    let toggleMap: AnyObserver<Bool>
    let togglePastEvents: AnyObserver<Bool>
    let toggleOverdueReminders: AnyObserver<Bool>
    let toggleRecurrenceIndicator: AnyObserver<Bool>
    let toggleForceLocalTimeZone: AnyObserver<Bool>
    let transparencyObserver: AnyObserver<Int>
    let textScalingObserver: AnyObserver<Double>
    let calendarTextScalingObserver: AnyObserver<Double>
    let calendarAppViewModeObserver: AnyObserver<CalendarViewMode>
    let defaultCalendarAppObserver: AnyObserver<CalendarApp>
    let appearanceModeObserver: AnyObserver<AppearanceMode>

    // Observables
    let autoLaunch: Observable<Bool>
    let showStatusItemIcon: Observable<Bool>
    let showStatusItemDate: Observable<Bool>
    let showStatusItemBackground: Observable<Bool>
    let openOnHover: Observable<Bool>
    let statusItemIconStyle: Observable<StatusItemIconStyle>
    let statusItemDateStyle: Observable<StatusItemDateStyle>
    let iconStyleOptions: Observable<[IconStyleOption]>
    let dateFormatOptions: Observable<[DateFormatOption]>
    let statusItemDateFormat: Observable<String>
    let isDateFormatInputVisible: Observable<Bool>
    let showEventStatusItem: Observable<Bool>
    let statusItemTextScaling: Observable<Double>
    let eventStatusItemCheckRange: Observable<Int>
    let eventStatusItemCheckRangeLabel: Observable<String>
    let eventStatusItemFlashing: Observable<Bool>
    let eventStatusItemSound: Observable<Bool>
    let eventStatusItemTextScaling: Observable<Double>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>
    let calendarScaling: Observable<Double>
    let firstWeekday: Observable<Int>
    let weekCount: Observable<Int>
    let highlightedWeekdays: Observable<[Int]>
    let highlightedWeekdaysOptions: Observable<[WeekDay]>
    let showWeekNumbers: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>
    let dateHoverOption: Observable<Bool>
    let showMap: Observable<Bool>
    let showPastEvents: Observable<Bool>
    let showOverdueReminders: Observable<Bool>
    let showRecurrenceIndicator: Observable<Bool>
    let forceLocalTimeZone: Observable<Bool>
    let popoverTransparency: Observable<Int>
    let popoverMaterial: Observable<PopoverMaterial>
    let textScaling: Observable<Double>
    let calendarTextScaling: Observable<Double>
    let calendarAppViewMode: Observable<CalendarViewMode>
    let defaultCalendarApp: Observable<CalendarApp>
    let appearanceMode: Observable<AppearanceMode>

    let isPresented = BehaviorSubject(value: false)

    private func localizedUnit(for mode: CalendarViewMode) -> String {

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        formatter.zeroFormattingBehavior = .dropAll
        formatter.calendar = dateProvider.calendar

        let components: DateComponents = switch mode {
            case .month: .init(month: 1)
            case .week: .init(weekOfMonth: 1)
            case .day: .init(day: 1)
        }

        return formatter.string(from: components)?.trimmingCharacters(in: .decimalDigits.union(.whitespaces)) ?? mode.rawValue
    }

    private(set) lazy var calendarAppViewModeOptions: [CalendarViewModeOption] = {

        return CalendarViewMode.allCases.map {
            let title = switch $0 {
            case .month:
                localizedUnit(for: .month)
            case .week:
                localizedUnit(for: .week)
            case .day:
                localizedUnit(for: .day)
            }

            return CalendarViewModeOption(mode: $0, title: title)
        }
    }()

    let calendarAppOptions: [CalendarAppOption]

    let dateFormatPlaceholder = AppConstants.defaultCustomDateFormat

    private let autoLauncher: AutoLauncher
    private let dateProvider: DateProviding

    init(
        autoLauncher: AutoLauncher,
        dateProvider: DateProviding,
        workspace: WorkspaceServiceProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter
    ) {
        self.autoLauncher = autoLauncher
        self.dateProvider = dateProvider

        // MARK: - Observers

        toggleAutoLaunch = autoLauncher.rx.observer(for: \.isEnabled)
        toggleStatusItemIcon = userDefaults.rx.observer(for: \.statusItemIconEnabled)
        toggleStatusItemDate = userDefaults.rx.observer(for: \.statusItemDateEnabled)
        toggleStatusItemBackground = userDefaults.rx.observer(for: \.statusItemBackgroundEnabled)
        toggleOpenOnHover = userDefaults.rx.observer(for: \.statusItemOpenOnHover)
        statusItemIconStyleObserver = userDefaults.rx.observer(for: \.statusItemIconStyle).mapObserver(\.rawValue)
        statusItemDateStyleObserver = userDefaults.rx.observer(for: \.statusItemDateStyle).mapObserver(\.rawValue)
        statusItemDateFormatObserver = userDefaults.rx.observer(for: \.statusItemDateFormat)
        toggleEventStatusItem = userDefaults.rx.observer(for: \.showEventStatusItem)
        statusItemTextScalingObserver = userDefaults.rx.observer(for: \.statusItemTextScaling)
        eventStatusItemCheckRangeObserver = userDefaults.rx.observer(for: \.eventStatusItemCheckRange)
        toggleEventStatusItemFlashing = userDefaults.rx.observer(for: \.eventStatusItemFlashing)
        toggleEventStatusItemSound = userDefaults.rx.observer(for: \.eventStatusItemSound)
        eventStatusItemTextScalingObserver = userDefaults.rx.observer(for: \.eventStatusItemTextScaling)
        eventStatusItemLengthObserver = userDefaults.rx.observer(for: \.eventStatusItemLength)
        toggleEventStatusItemDetectNotch = userDefaults.rx.observer(for: \.eventStatusItemDetectNotch)
        calendarScalingObserver = userDefaults.rx.observer(for: \.calendarScaling)
        firstWeekdayPrevObserver = userDefaults.rx.observer(for: \.firstWeekday).mapObserver { (1...7).circular(before: userDefaults.firstWeekday) }
        firstWeekdayNextObserver = userDefaults.rx.observer(for: \.firstWeekday).mapObserver { (1...7).circular(after: userDefaults.firstWeekday) }
        toggleHighlightedWeekday = userDefaults.rx.toggleObserver(for: \.highlightedWeekdays)
        weekCountObserver = userDefaults.rx.observer(for: \.weekCount)
        toggleWeekNumbers = userDefaults.rx.observer(for: \.showWeekNumbers)
        toggleDeclinedEvents = userDefaults.rx.observer(for: \.showDeclinedEvents)
        togglePreserveSelectedDate = userDefaults.rx.observer(for: \.preserveSelectedDate)
        toggleDateHoverOption = userDefaults.rx.observer(for: \.dateHoverOption)
        toggleMap = userDefaults.rx.observer(for: \.showMap)
        togglePastEvents = userDefaults.rx.observer(for: \.showPastEvents)
        toggleOverdueReminders = userDefaults.rx.observer(for: \.showOverdueReminders)
        toggleRecurrenceIndicator = userDefaults.rx.observer(for: \.showRecurrenceIndicator)
        toggleForceLocalTimeZone = userDefaults.rx.observer(for: \.forceLocalTimeZone)
        transparencyObserver = userDefaults.rx.observer(for: \.transparencyLevel)
        textScalingObserver = userDefaults.rx.observer(for: \.textScaling)
        calendarTextScalingObserver = userDefaults.rx.observer(for: \.calendarTextScaling)
        calendarAppViewModeObserver = userDefaults.rx.observer(for: \.calendarAppViewMode).mapObserver(\.rawValue)
        defaultCalendarAppObserver = userDefaults.rx.observer(for: \.defaultCalendarApp).mapObserver(\.rawValue)
        appearanceModeObserver = userDefaults.rx.observer(for: \.appearanceMode).mapObserver(\.rawValue)

        // MARK: - Observables

        autoLaunch = autoLauncher.rx.observe(\.isEnabled)

        /* ----- Icon and Date ----- */
        let statusItemIconAndDate = Observable.combineLatest(
            userDefaults.rx.observe(\.statusItemIconEnabled),
            userDefaults.rx.observe(\.statusItemDateEnabled)
        )
        .map { iconEnabled, dateEnabled in
            (iconEnabled || !dateEnabled, dateEnabled)
        }

        showStatusItemIcon = statusItemIconAndDate.map(\.0)
        showStatusItemDate = statusItemIconAndDate.map(\.1)
        /* ----------------------- */

        openOnHover = userDefaults.rx.observe(\.statusItemOpenOnHover)
        showStatusItemBackground = userDefaults.rx.observe(\.statusItemBackgroundEnabled)
        statusItemIconStyle = userDefaults.rx.observe(\.statusItemIconStyle).map { .init(rawValue: $0) ?? .calendar }
        statusItemDateStyle = userDefaults.rx.observe(\.statusItemDateStyle).map { .init(rawValue: $0) ?? .none }
        statusItemDateFormat = userDefaults.rx.observe(\.statusItemDateFormat)
        showEventStatusItem = userDefaults.rx.observe(\.showEventStatusItem)
        statusItemTextScaling = userDefaults.rx.observe(\.statusItemTextScaling)
        eventStatusItemCheckRange = userDefaults.rx.observe(\.eventStatusItemCheckRange)
        eventStatusItemFlashing = userDefaults.rx.observe(\.eventStatusItemFlashing)
        eventStatusItemSound = userDefaults.rx.observe(\.eventStatusItemSound)
        eventStatusItemTextScaling = userDefaults.rx.observe(\.eventStatusItemTextScaling)
        eventStatusItemLength = userDefaults.rx.observe(\.eventStatusItemLength)
        eventStatusItemDetectNotch = userDefaults.rx.observe(\.eventStatusItemDetectNotch)
        calendarScaling = userDefaults.rx.observe(\.calendarScaling)
        firstWeekday = userDefaults.rx.observe(\.firstWeekday)
        highlightedWeekdays = userDefaults.rx.observe(\.highlightedWeekdays)
        weekCount = userDefaults.rx.observe(\.weekCount)
        showWeekNumbers = userDefaults.rx.observe(\.showWeekNumbers)
        showDeclinedEvents = userDefaults.rx.observe(\.showDeclinedEvents)
        preserveSelectedDate = userDefaults.rx.observe(\.preserveSelectedDate)
        dateHoverOption = userDefaults.rx.observe(\.dateHoverOption)
        showMap = userDefaults.rx.observe(\.showMap)
        showPastEvents = userDefaults.rx.observe(\.showPastEvents)
        showOverdueReminders = userDefaults.rx.observe(\.showOverdueReminders)
        showRecurrenceIndicator = userDefaults.rx.observe(\.showRecurrenceIndicator)
        forceLocalTimeZone = userDefaults.rx.observe(\.forceLocalTimeZone)
        popoverTransparency = userDefaults.rx.observe(\.transparencyLevel)
        textScaling = userDefaults.rx.observe(\.textScaling)
        calendarTextScaling = userDefaults.rx.observe(\.calendarTextScaling)
        calendarAppViewMode = userDefaults.rx.observe(\.calendarAppViewMode).map { .init(rawValue: $0) ?? .month }
        defaultCalendarApp = userDefaults.rx.observe(\.defaultCalendarApp).map { .init(rawValue: $0) ?? .calendar }
        appearanceMode = userDefaults.rx.observe(\.appearanceMode).map { .init(rawValue: $0) ?? .automatic }

        let localeChangeObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .void()
            .startWith(())
            .share(replay: 1)

        let calendarChangeObservable = Observable
            .merge(
                notificationCenter.rx.notification(NSLocale.currentLocaleDidChangeNotification).void(),
                notificationCenter.rx.notification(.NSCalendarDayChanged).void()
            )
            .startWith(())
            .share(replay: 1)

        iconStyleOptions = calendarChangeObservable
            .map {
                StatusItemIconStyle.allCases.map {
                    let icon = StatusItemIconFactory.icon(
                        size: 15,
                        style: $0,
                        textScaling: 1.2,
                        dateProvider: dateProvider
                    )
                    return IconStyleOption(style: $0, image: icon, title: $0.rawValue)
                }
            }
            .share(replay: 1)

        dateFormatOptions = calendarChangeObservable
            .map {
                let dateFormatter = DateFormatter(calendar: dateProvider.calendar)
                var options: [DateFormatOption] = []

                for option in StatusItemDateStyle.allCases {
                    dateFormatter.dateStyle = option
                    let title = dateFormatter.string(from: dateProvider.now)
                    guard !options.contains(where: { $0.title == title }) else { continue }
                    options.append(.init(style: option, title: title))
                }

                options.append(.init(style: .none, title: "\(Strings.Settings.MenuBar.dateFormatCustom)..."))

                return options
            }
            .share(replay: 1)

        isDateFormatInputVisible = statusItemDateStyle.map(\.isCustom).share(replay: 1)

        eventStatusItemCheckRangeLabel = eventStatusItemCheckRange
            .repeat(when: calendarChangeObservable)
            .map { range in
                let dateFormatter = DateComponentsFormatter()
                dateFormatter.calendar = dateProvider.calendar
                dateFormatter.unitsStyle = .abbreviated

                return Strings.Formatter.Date.Relative.in(
                    dateFormatter.string(from: DateComponents(hour: range))!
                )
            }
            .share(replay: 1)

        highlightedWeekdaysOptions = Observable
            .combineLatest(highlightedWeekdays, firstWeekday)
            .repeat(when: localeChangeObservable)
            .map { highlightedWeekdays, firstWeekday in
                let calendar = dateProvider.calendar
                return (firstWeekday ..< firstWeekday + 7)
                    .map {
                        let weekDay = ($0 - 1) % 7
                        return WeekDay(
                            title: calendar.veryShortWeekdaySymbols[weekDay],
                            isHighlighted: highlightedWeekdays.contains(weekDay),
                            index: weekDay
                        )
                    }
            }
            .share(replay: 1)

        popoverMaterial = popoverTransparency.map(PopoverMaterial.init(transparency:))

        calendarAppOptions = CalendarApp.allCases.compactMap { app -> CalendarAppOption? in
            guard
                let url = workspace.urlForApplication(toOpen: app.baseURL),
                url.lastPathComponent.hasSuffix(".app"),
                url.deletingLastPathComponent().lastPathComponent == "Applications",
                let res = try? url.resourceValues(forKeys: [.nameKey, .effectiveIconKey]),
                let icon = res.effectiveIcon as? NSImage,
                let name = res.name
            else {
                return nil
            }
            return .init(
                id: app,
                icon: icon,
                name: String(name.dropLast(4))
            )
        }
    }

    func windowDidBecomeKey() {
        autoLauncher.syncStatus()
    }
}
