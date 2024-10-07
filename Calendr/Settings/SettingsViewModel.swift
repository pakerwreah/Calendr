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
    var showEventStatusItem: Observable<Bool> { get }
}

protocol CalendarSettings {
    var calendarScaling: Observable<Double> { get }
    var textScaling: Observable<Double> { get }
    var calendarTextScaling: Observable<Double> { get }
    var firstWeekday: Observable<Int> { get }
    var highlightedWeekdays: Observable<[Int]> { get }
    var showWeekNumbers: Observable<Bool> { get }
    var showDeclinedEvents: Observable<Bool> { get }
    var preserveSelectedDate: Observable<Bool> { get }
    var dateHoverOption: Observable<Bool> { get }
}

protocol AppearanceSettings {
    var popoverMaterial: Observable<PopoverMaterial> { get }
    var textScaling: Observable<Double> { get }
    var calendarTextScaling: Observable<Double> { get }
}

protocol EventDetailsSettings: AppearanceSettings {
    var showMap: Observable<Bool> { get }
}

protocol EventListSettings: EventDetailsSettings {
    var showPastEvents: Observable<Bool> { get }
}

protocol NextEventSettings: EventDetailsSettings {
    var showEventStatusItem: Observable<Bool> { get }
    var eventStatusItemFontSize: Observable<Float> { get }
    var eventStatusItemCheckRange: Observable<Int> { get }
    var eventStatusItemLength: Observable<Int> { get }
    var eventStatusItemDetectNotch: Observable<Bool> { get }
}

class SettingsViewModel:
    StatusItemSettings, NextEventSettings, CalendarSettings,
    EventListSettings, EventDetailsSettings, AppearanceSettings {

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
    let eventStatusItemFontSizeObserver: AnyObserver<Float>
    let eventStatusItemCheckRangeObserver: AnyObserver<Int>
    let eventStatusItemLengthObserver: AnyObserver<Int>
    let toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    let calendarScalingObserver: AnyObserver<Double>
    let firstWeekdayPrevObserver: AnyObserver<Void>
    let firstWeekdayNextObserver: AnyObserver<Void>
    let toggleHighlightedWeekday: AnyObserver<Int>
    let toggleWeekNumbers: AnyObserver<Bool>
    let toggleDeclinedEvents: AnyObserver<Bool>
    let togglePreserveSelectedDate: AnyObserver<Bool>
    let toggleDateHoverOption: AnyObserver<Bool>
    let toggleMap: AnyObserver<Bool>
    let togglePastEvents: AnyObserver<Bool>
    let transparencyObserver: AnyObserver<Int>
    let textScalingObserver: AnyObserver<Double>
    let calendarTextScalingObserver: AnyObserver<Double>

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
    let isDateFormatInputVisible: Observable<Bool>
    let showEventStatusItem: Observable<Bool>
    let eventStatusItemFontSize: Observable<Float>
    let eventStatusItemCheckRange: Observable<Int>
    let eventStatusItemCheckRangeLabel: Observable<String>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>
    let calendarScaling: Observable<Double>
    let firstWeekday: Observable<Int>
    let highlightedWeekdays: Observable<[Int]>
    let highlightedWeekdaysOptions: Observable<[WeekDay]>
    let showWeekNumbers: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>
    let dateHoverOption: Observable<Bool>
    let showMap: Observable<Bool>
    let showPastEvents: Observable<Bool>
    let popoverTransparency: Observable<Int>
    let popoverMaterial: Observable<PopoverMaterial>
    let textScaling: Observable<Double>
    let calendarTextScaling: Observable<Double>

    let isPresented = BehaviorSubject(value: false)

    let dateFormatPlaceholder = AppConstants.defaultCustomDateFormat

    private let autoLauncher: AutoLauncher

    init(
        autoLauncher: AutoLauncher,
        dateProvider: DateProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter
    ) {
        self.autoLauncher = autoLauncher

        // MARK: - Observers

        toggleAutoLaunch = autoLauncher.rx.observer(for: \.isEnabled)
        toggleStatusItemIcon = userDefaults.rx.observer(for: \.statusItemIconEnabled)
        toggleStatusItemDate = userDefaults.rx.observer(for: \.statusItemDateEnabled)
        toggleStatusItemBackground = userDefaults.rx.observer(for: \.statusItemBackgroundEnabled)
        statusItemIconStyleObserver = userDefaults.rx.observer(for: \.statusItemIconStyle).mapObserver(\.rawValue)
        statusItemDateStyleObserver = userDefaults.rx.observer(for: \.statusItemDateStyle).mapObserver(\.rawValue)
        statusItemDateFormatObserver = userDefaults.rx.observer(for: \.statusItemDateFormat)
        toggleEventStatusItem = userDefaults.rx.observer(for: \.showEventStatusItem)
        eventStatusItemFontSizeObserver = userDefaults.rx.observer(for: \.eventStatusItemFontSize)
        eventStatusItemCheckRangeObserver = userDefaults.rx.observer(for: \.eventStatusItemCheckRange)
        eventStatusItemLengthObserver = userDefaults.rx.observer(for: \.eventStatusItemLength)
        toggleEventStatusItemDetectNotch = userDefaults.rx.observer(for: \.eventStatusItemDetectNotch)
        calendarScalingObserver = userDefaults.rx.observer(for: \.calendarScaling)
        firstWeekdayPrevObserver = userDefaults.rx.observer(for: \.firstWeekday).mapObserver { (1...7).circular(before: userDefaults.firstWeekday) }
        firstWeekdayNextObserver = userDefaults.rx.observer(for: \.firstWeekday).mapObserver { (1...7).circular(after: userDefaults.firstWeekday) }
        toggleHighlightedWeekday = userDefaults.rx.toggleObserver(for: \.highlightedWeekdays)
        toggleWeekNumbers = userDefaults.rx.observer(for: \.showWeekNumbers)
        toggleDeclinedEvents = userDefaults.rx.observer(for: \.showDeclinedEvents)
        togglePreserveSelectedDate = userDefaults.rx.observer(for: \.preserveSelectedDate)
        toggleDateHoverOption = userDefaults.rx.observer(for: \.dateHoverOption)
        toggleMap = userDefaults.rx.observer(for: \.showMap)
        togglePastEvents = userDefaults.rx.observer(for: \.showPastEvents)
        transparencyObserver = userDefaults.rx.observer(for: \.transparencyLevel)
        textScalingObserver = userDefaults.rx.observer(for: \.textScaling)
        calendarTextScalingObserver = userDefaults.rx.observer(for: \.calendarTextScaling)

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
        eventStatusItemFontSize = userDefaults.rx.observe(\.eventStatusItemFontSize)
        eventStatusItemCheckRange = userDefaults.rx.observe(\.eventStatusItemCheckRange)
        eventStatusItemLength = userDefaults.rx.observe(\.eventStatusItemLength)
        eventStatusItemDetectNotch = userDefaults.rx.observe(\.eventStatusItemDetectNotch)
        calendarScaling = userDefaults.rx.observe(\.calendarScaling)
        firstWeekday = userDefaults.rx.observe(\.firstWeekday)
        highlightedWeekdays = userDefaults.rx.observe(\.highlightedWeekdays)
        showWeekNumbers = userDefaults.rx.observe(\.showWeekNumbers)
        showDeclinedEvents = userDefaults.rx.observe(\.showDeclinedEvents)
        preserveSelectedDate = userDefaults.rx.observe(\.preserveSelectedDate)
        dateHoverOption = userDefaults.rx.observe(\.dateHoverOption)
        showMap = userDefaults.rx.observe(\.showMap)
        showPastEvents = userDefaults.rx.observe(\.showPastEvents)
        popoverTransparency = userDefaults.rx.observe(\.transparencyLevel)
        textScaling = userDefaults.rx.observe(\.textScaling)
        calendarTextScaling = userDefaults.rx.observe(\.calendarTextScaling)

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
    }

    func windowDidBecomeKey() {
        autoLauncher.syncStatus()
    }
}
