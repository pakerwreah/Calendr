//
//  SettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 16/01/21.
//

import Cocoa
import RxSwift

typealias StatusItemDateStyle = DateFormatter.Style

extension StatusItemDateStyle {
    static let allCases: [Self] = [.short, .medium, .long, .full]
    var isCustom: Bool { !Self.allCases.contains(self) }
}

typealias PopoverMaterial = NSVisualEffectView.Material

extension PopoverMaterial {

    init(transparency: Int) {
        self = [
            .contentBackground,
            .sheet,
            .headerView,
            .menu,
            .popover,
            .hudWindow
        ][transparency]
    }
}

enum StatusItemIconStyle: String, CaseIterable {
    case calendar
    case date
    case dayOfWeek
}

protocol StatusItemSettings {
    var showStatusItemIcon: Observable<Bool> { get }
    var showStatusItemDate: Observable<Bool> { get }
    var showStatusItemBackground: Observable<Bool> { get }
    var statusItemIconStyle: Observable<StatusItemIconStyle> { get }
    var statusItemDateStyle: Observable<StatusItemDateStyle> { get }
    var statusItemDateFormat: Observable<String> { get }
    var eventStatusItemDetectNotch: Observable<Bool> { get }
}

protocol CalendarSettings {
    var calendarScaling: Observable<Double> { get }
    var highlightedWeekdays: Observable<[Int]> { get }
    var showWeekNumbers: Observable<Bool> { get }
    var showDeclinedEvents: Observable<Bool> { get }
    var preserveSelectedDate: Observable<Bool> { get }
}

protocol PopoverSettings {
    var popoverMaterial: Observable<PopoverMaterial> { get }
}

protocol EventListSettings: PopoverSettings {
    var showPastEvents: Observable<Bool> { get }
}

protocol NextEventSettings: PopoverSettings {
    var showEventStatusItem: Observable<Bool> { get }
    var eventStatusItemCheckRange: Observable<Int> { get }
    var eventStatusItemLength: Observable<Int> { get }
    var eventStatusItemDetectNotch: Observable<Bool> { get }
}

class SettingsViewModel: StatusItemSettings, NextEventSettings, CalendarSettings, EventListSettings  {

    struct IconStyleOption: Equatable {
        let style: StatusItemIconStyle
        let image: NSImage
        let title: String
    }

    struct DateFormatOption: Equatable {
        let style: StatusItemDateStyle
        let title: String
    }

    // Observers
    let toggleAutoLaunch: AnyObserver<Bool>
    let toggleStatusItemIcon: AnyObserver<Bool>
    let toggleStatusItemDate: AnyObserver<Bool>
    let toggleStatusItemBackground: AnyObserver<Bool>
    let statusItemIconStyleObserver: AnyObserver<StatusItemIconStyle>
    let statusItemDateStyleObserver: AnyObserver<StatusItemDateStyle>
    let statusItemDateFormatObserver: AnyObserver<String>
    let toggleEventStatusItem: AnyObserver<Bool>
    let eventStatusItemCheckRangeObserver: AnyObserver<Int>
    let eventStatusItemLengthObserver: AnyObserver<Int>
    let toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    let calendarScalingObserver: AnyObserver<Double>
    let toggleHighlightedWeekday: AnyObserver<Int>
    let toggleWeekNumbers: AnyObserver<Bool>
    let toggleDeclinedEvents: AnyObserver<Bool>
    let togglePreserveSelectedDate: AnyObserver<Bool>
    let togglePastEvents: AnyObserver<Bool>
    let transparencyObserver: AnyObserver<Int>

    // Observables
    let autoLaunch: Observable<Bool>
    let showStatusItemIcon: Observable<Bool>
    let showStatusItemDate: Observable<Bool>
    let showStatusItemBackground: Observable<Bool>
    let statusItemIconStyle: Observable<StatusItemIconStyle>
    let statusItemDateStyle: Observable<StatusItemDateStyle>
    let iconStyleOptions: Observable<[IconStyleOption]>
    let dateFormatOptions: Observable<[DateFormatOption]>
    let statusItemDateFormat: Observable<String>
    let dateFormatPlaceholder = "E d MMM YYYY"
    let isDateFormatInputVisible: Observable<Bool>
    let showEventStatusItem: Observable<Bool>
    let eventStatusItemCheckRange: Observable<Int>
    let eventStatusItemCheckRangeLabel: Observable<String>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>
    let calendarScaling: Observable<Double>
    let highlightedWeekdays: Observable<[Int]>
    let highlightedWeekdaysOptions: Observable<[WeekDay]>
    let showWeekNumbers: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>
    let showPastEvents: Observable<Bool>
    let popoverTransparency: Observable<Int>
    let popoverMaterial: Observable<PopoverMaterial>

    init(
        autoLauncher: AutoLauncher,
        dateProvider: DateProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter
    ) {

        userDefaults.register(defaults: [
            Prefs.statusItemIconEnabled: true,
            Prefs.statusItemDateEnabled: true,
            Prefs.statusItemBackgroundEnabled: false,
            Prefs.statusItemIconStyle: StatusItemIconStyle.calendar.rawValue,
            Prefs.statusItemDateStyle: StatusItemDateStyle.short.rawValue,
            Prefs.statusItemDateFormat: dateFormatPlaceholder,
            Prefs.showEventStatusItem: false,
            Prefs.eventStatusItemCheckRange: 6,
            Prefs.eventStatusItemLength: 18,
            Prefs.eventStatusItemDetectNotch: false,
            Prefs.calendarScaling: 1,
            Prefs.highlightedWeekdays: [0, 6],
            Prefs.showWeekNumbers: false,
            Prefs.showDeclinedEvents: false,
            Prefs.preserveSelectedDate: false,
            Prefs.showPastEvents: true,
            Prefs.transparencyLevel: 2
        ])

        // MARK: - Observers

        toggleAutoLaunch = autoLauncher.rx.observer(for: \.isEnabled)
        toggleStatusItemIcon = userDefaults.rx.observer(for: \.statusItemIconEnabled)
        toggleStatusItemDate = userDefaults.rx.observer(for: \.statusItemDateEnabled)
        toggleStatusItemBackground = userDefaults.rx.observer(for: \.statusItemBackgroundEnabled)
        statusItemIconStyleObserver = userDefaults.rx.observer(for: \.statusItemIconStyle).mapObserver(\.rawValue)
        statusItemDateStyleObserver = userDefaults.rx.observer(for: \.statusItemDateStyle).mapObserver(\.rawValue)
        statusItemDateFormatObserver = userDefaults.rx.observer(for: \.statusItemDateFormat)
        toggleEventStatusItem = userDefaults.rx.observer(for: \.showEventStatusItem)
        eventStatusItemCheckRangeObserver = userDefaults.rx.observer(for: \.eventStatusItemCheckRange)
        eventStatusItemLengthObserver = userDefaults.rx.observer(for: \.eventStatusItemLength)
        toggleEventStatusItemDetectNotch = userDefaults.rx.observer(for: \.eventStatusItemDetectNotch)
        calendarScalingObserver = userDefaults.rx.observer(for: \.calendarScaling)
        toggleHighlightedWeekday = userDefaults.rx.toggleObserver(for: \.highlightedWeekdays)
        toggleWeekNumbers = userDefaults.rx.observer(for: \.showWeekNumbers)
        toggleDeclinedEvents = userDefaults.rx.observer(for: \.showDeclinedEvents)
        togglePreserveSelectedDate = userDefaults.rx.observer(for: \.preserveSelectedDate)
        togglePastEvents = userDefaults.rx.observer(for: \.showPastEvents)
        transparencyObserver = userDefaults.rx.observer(for: \.transparencyLevel)

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

        showStatusItemBackground = userDefaults.rx.observe(\.statusItemBackgroundEnabled)
        statusItemIconStyle = userDefaults.rx.observe(\.statusItemIconStyle).map { StatusItemIconStyle(rawValue: $0) ?? .calendar }
        statusItemDateStyle = userDefaults.rx.observe(\.statusItemDateStyle).map { StatusItemDateStyle(rawValue: $0) ?? .none }
        statusItemDateFormat = userDefaults.rx.observe(\.statusItemDateFormat)
        showEventStatusItem = userDefaults.rx.observe(\.showEventStatusItem)
        eventStatusItemCheckRange = userDefaults.rx.observe(\.eventStatusItemCheckRange)
        eventStatusItemLength = userDefaults.rx.observe(\.eventStatusItemLength)
        eventStatusItemDetectNotch = userDefaults.rx.observe(\.eventStatusItemDetectNotch)
        calendarScaling = userDefaults.rx.observe(\.calendarScaling)
        highlightedWeekdays = userDefaults.rx.observe(\.highlightedWeekdays)
        showWeekNumbers = userDefaults.rx.observe(\.showWeekNumbers)
        showDeclinedEvents = userDefaults.rx.observe(\.showDeclinedEvents)
        preserveSelectedDate = userDefaults.rx.observe(\.preserveSelectedDate)
        showPastEvents = userDefaults.rx.observe(\.showPastEvents)
        popoverTransparency = userDefaults.rx.observe(\.transparencyLevel)

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
                    let icon = StatusItemIconFactory.icon(size: .init(15), style: $0, dateProvider: dateProvider)
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

        isDateFormatInputVisible = Observable.combineLatest(
            showStatusItemDate,
            statusItemDateStyle.map(\.isCustom)
        )
        .map { $0 && $1 }
        .distinctUntilChanged()
        .share(replay: 1)

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

        highlightedWeekdaysOptions = highlightedWeekdays
            .repeat(when: calendarChangeObservable)
            .map { highlightedWeekdays in
                let calendar = dateProvider.calendar
                return (calendar.firstWeekday ..< calendar.firstWeekday + 7)
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
    }
}
