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
    var eventDotsStyle: Observable<EventDotsStyle> { get }
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
    var showAllDayDetails: Observable<Bool> { get }
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
    let toggleAllDayDetails: AnyObserver<Bool>
    let toggleRecurrenceIndicator: AnyObserver<Bool>
    let toggleForceLocalTimeZone: AnyObserver<Bool>
    let transparencyObserver: AnyObserver<Int>
    let textScalingObserver: AnyObserver<Double>
    let calendarTextScalingObserver: AnyObserver<Double>
    let eventDotsStyleObserver: AnyObserver<EventDotsStyle>
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
    let showAllDayDetails: Observable<Bool>
    let showRecurrenceIndicator: Observable<Bool>
    let forceLocalTimeZone: Observable<Bool>
    let popoverTransparency: Observable<Int>
    let popoverMaterial: Observable<PopoverMaterial>
    let textScaling: Observable<Double>
    let calendarTextScaling: Observable<Double>
    let eventDotsStyle: Observable<EventDotsStyle>
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
    private let localStorage: LocalStorageProvider

    init(
        autoLauncher: AutoLauncher,
        dateProvider: DateProviding,
        workspace: WorkspaceServiceProviding,
        localStorage: LocalStorageProvider,
        notificationCenter: NotificationCenter
    ) {
        self.autoLauncher = autoLauncher
        self.dateProvider = dateProvider
        self.localStorage = localStorage

        // MARK: - Observers

        toggleAutoLaunch = autoLauncher.rx.observer(for: \.isEnabled)
        toggleStatusItemIcon = localStorage.rx.observer(for: \.statusItemIconEnabled)
        toggleStatusItemDate = localStorage.rx.observer(for: \.statusItemDateEnabled)
        toggleStatusItemBackground = localStorage.rx.observer(for: \.statusItemBackgroundEnabled)
        toggleOpenOnHover = localStorage.rx.observer(for: \.statusItemOpenOnHover)
        statusItemIconStyleObserver = localStorage.rx.observer(for: \.statusItemIconStyle).mapObserver(\.rawValue)
        statusItemDateStyleObserver = localStorage.rx.observer(for: \.statusItemDateStyle).mapObserver(\.rawValue)
        statusItemDateFormatObserver = localStorage.rx.observer(for: \.statusItemDateFormat)
        toggleEventStatusItem = localStorage.rx.observer(for: \.showEventStatusItem)
        statusItemTextScalingObserver = localStorage.rx.observer(for: \.statusItemTextScaling)
        eventStatusItemCheckRangeObserver = localStorage.rx.observer(for: \.eventStatusItemCheckRange)
        toggleEventStatusItemFlashing = localStorage.rx.observer(for: \.eventStatusItemFlashing)
        toggleEventStatusItemSound = localStorage.rx.observer(for: \.eventStatusItemSound)
        eventStatusItemTextScalingObserver = localStorage.rx.observer(for: \.eventStatusItemTextScaling)
        eventStatusItemLengthObserver = localStorage.rx.observer(for: \.eventStatusItemLength)
        toggleEventStatusItemDetectNotch = localStorage.rx.observer(for: \.eventStatusItemDetectNotch)
        calendarScalingObserver = localStorage.rx.observer(for: \.calendarScaling)
        firstWeekdayPrevObserver = localStorage.rx.observer(for: \.firstWeekday).mapObserver { (1...7).circular(before: localStorage.firstWeekday) }
        firstWeekdayNextObserver = localStorage.rx.observer(for: \.firstWeekday).mapObserver { (1...7).circular(after: localStorage.firstWeekday) }
        toggleHighlightedWeekday = localStorage.rx.toggleObserver(for: \.highlightedWeekdays)
        weekCountObserver = localStorage.rx.observer(for: \.weekCount)
        toggleWeekNumbers = localStorage.rx.observer(for: \.showWeekNumbers)
        toggleDeclinedEvents = localStorage.rx.observer(for: \.showDeclinedEvents)
        togglePreserveSelectedDate = localStorage.rx.observer(for: \.preserveSelectedDate)
        toggleDateHoverOption = localStorage.rx.observer(for: \.dateHoverOption)
        toggleMap = localStorage.rx.observer(for: \.showMap)
        togglePastEvents = localStorage.rx.observer(for: \.showPastEvents)
        toggleOverdueReminders = localStorage.rx.observer(for: \.showOverdueReminders)
        toggleAllDayDetails = localStorage.rx.observer(for: \.showAllDayDetails)
        toggleRecurrenceIndicator = localStorage.rx.observer(for: \.showRecurrenceIndicator)
        toggleForceLocalTimeZone = localStorage.rx.observer(for: \.forceLocalTimeZone)
        transparencyObserver = localStorage.rx.observer(for: \.transparencyLevel)
        textScalingObserver = localStorage.rx.observer(for: \.textScaling)
        calendarTextScalingObserver = localStorage.rx.observer(for: \.calendarTextScaling)
        eventDotsStyleObserver = localStorage.rx.observer(for: \.eventDotsStyle).mapObserver(\.rawValue)
        calendarAppViewModeObserver = localStorage.rx.observer(for: \.calendarAppViewMode).mapObserver(\.rawValue)
        defaultCalendarAppObserver = localStorage.rx.observer(for: \.defaultCalendarApp).mapObserver(\.rawValue)
        appearanceModeObserver = localStorage.rx.observer(for: \.appearanceMode).mapObserver(\.rawValue)

        // MARK: - Observables

        autoLaunch = autoLauncher.rx.observe(\.isEnabled)

        openOnHover = localStorage.rx.observe(\.statusItemOpenOnHover)
        showStatusItemIcon = localStorage.rx.observe(\.statusItemIconEnabled)
        showStatusItemDate = localStorage.rx.observe(\.statusItemDateEnabled)
        showStatusItemBackground = localStorage.rx.observe(\.statusItemBackgroundEnabled)
        statusItemIconStyle = localStorage.rx.observe(\.statusItemIconStyle).map { .init(rawValue: $0) ?? .calendar }
        statusItemDateStyle = localStorage.rx.observe(\.statusItemDateStyle).map { .init(rawValue: $0) ?? .none }
        statusItemDateFormat = localStorage.rx.observe(\.statusItemDateFormat)
        showEventStatusItem = localStorage.rx.observe(\.showEventStatusItem)
        statusItemTextScaling = localStorage.rx.observe(\.statusItemTextScaling)
        eventStatusItemCheckRange = localStorage.rx.observe(\.eventStatusItemCheckRange)
        eventStatusItemFlashing = localStorage.rx.observe(\.eventStatusItemFlashing)
        eventStatusItemSound = localStorage.rx.observe(\.eventStatusItemSound)
        eventStatusItemTextScaling = localStorage.rx.observe(\.eventStatusItemTextScaling)
        eventStatusItemLength = localStorage.rx.observe(\.eventStatusItemLength)
        eventStatusItemDetectNotch = localStorage.rx.observe(\.eventStatusItemDetectNotch)
        calendarScaling = localStorage.rx.observe(\.calendarScaling)
        firstWeekday = localStorage.rx.observe(\.firstWeekday)
        highlightedWeekdays = localStorage.rx.observe(\.highlightedWeekdays)
        weekCount = localStorage.rx.observe(\.weekCount)
        showWeekNumbers = localStorage.rx.observe(\.showWeekNumbers)
        showDeclinedEvents = localStorage.rx.observe(\.showDeclinedEvents)
        preserveSelectedDate = localStorage.rx.observe(\.preserveSelectedDate)
        dateHoverOption = localStorage.rx.observe(\.dateHoverOption)
        showMap = localStorage.rx.observe(\.showMap)
        showPastEvents = localStorage.rx.observe(\.showPastEvents)
        showOverdueReminders = localStorage.rx.observe(\.showOverdueReminders)
        showAllDayDetails = localStorage.rx.observe(\.showAllDayDetails)
        showRecurrenceIndicator = localStorage.rx.observe(\.showRecurrenceIndicator)
        forceLocalTimeZone = localStorage.rx.observe(\.forceLocalTimeZone)
        popoverTransparency = localStorage.rx.observe(\.transparencyLevel)
        textScaling = localStorage.rx.observe(\.textScaling)
        calendarTextScaling = localStorage.rx.observe(\.calendarTextScaling)
        eventDotsStyle = localStorage.rx.observe(\.eventDotsStyle).map { .init(rawValue: $0) ?? .none }
        calendarAppViewMode = localStorage.rx.observe(\.calendarAppViewMode).map { .init(rawValue: $0) ?? .month }
        defaultCalendarApp = localStorage.rx.observe(\.defaultCalendarApp).map { .init(rawValue: $0) ?? .calendar }
        appearanceMode = localStorage.rx.observe(\.appearanceMode).map { .init(rawValue: $0) ?? .automatic }

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

                options.append(.init(style: .none, title: Strings.Settings.MenuBar.dateFormatCustom))

                return options
            }
            .share(replay: 1)

        isDateFormatInputVisible = statusItemDateStyle.map(\.isCustom).share(replay: 1)

        eventStatusItemCheckRangeLabel = eventStatusItemCheckRange
            .repeat(when: calendarChangeObservable)
            .map { hours in
                let dateFormatter = DateComponentsFormatter()
                dateFormatter.calendar = dateProvider.calendar
                dateFormatter.unitsStyle = .abbreviated

                return Strings.Formatter.Date.Relative.in(
                    dateFormatter.string(
                        from: hours > 0 ? DateComponents(hour: hours) : DateComponents(minute: 30)
                    )!
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

        if let appId = defaultCalendarApp.lastValue(), !calendarAppOptions.contains(where: { $0.id == appId }) {
            print("💡 Previous calendar app missing. Defaulting to Calendar.app")
            defaultCalendarAppObserver.onNext(.calendar)
        }
    }

    func windowDidBecomeKey() {
        autoLauncher.syncStatus()
    }

    func mapBlackListViewModel() -> MapBlackListViewModel {
        MapBlackListViewModel(localStorage: localStorage)
    }
}
