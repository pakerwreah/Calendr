//
//  SettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 16/01/21.
//

import Cocoa
import RxSwift

typealias DateStyle = DateFormatter.Style
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

protocol StatusItemSettings {
    var showStatusItemIcon: Observable<Bool> { get }
    var showStatusItemDate: Observable<Bool> { get }
    var statusItemDateStyle: Observable<DateStyle> { get }
    var eventStatusItemDetectNotch: Observable<Bool> { get }
}

protocol CalendarSettings {
    var showWeekNumbers: Observable<Bool> { get }
    var showDeclinedEvents: Observable<Bool> { get }
    var preserveSelectedDate: Observable<Bool> { get }
    var calendarScaling: Observable<Double> { get }
}

protocol PopoverSettings {
    var popoverMaterial: Observable<PopoverMaterial> { get }
}

protocol EventListSettings: PopoverSettings {
    var showPastEvents: Observable<Bool> { get }
}

protocol NextEventSettings: PopoverSettings {
    var showEventStatusItem: Observable<Bool> { get }
    var eventStatusItemLength: Observable<Int> { get }
    var eventStatusItemDetectNotch: Observable<Bool> { get }
}

class SettingsViewModel: StatusItemSettings, NextEventSettings, CalendarSettings, EventListSettings  {

    // Observers
    let toggleStatusItemIcon: AnyObserver<Bool>
    let toggleStatusItemDate: AnyObserver<Bool>
    let statusItemDateStyleObserver: AnyObserver<DateStyle>
    let toggleEventStatusItem: AnyObserver<Bool>
    let eventStatusItemLengthObserver: AnyObserver<Int>
    let toggleEventStatusItemDetectNotch: AnyObserver<Bool>
    let toggleWeekNumbers: AnyObserver<Bool>
    let toggleDeclinedEvents: AnyObserver<Bool>
    let togglePreserveSelectedDate: AnyObserver<Bool>
    let togglePastEvents: AnyObserver<Bool>
    let transparencyObserver: AnyObserver<Int>
    let calendarScalingObserver: AnyObserver<Double>

    // Observables
    var showStatusItemIcon: Observable<Bool>
    var showStatusItemDate: Observable<Bool>
    var statusItemDateStyle: Observable<DateStyle>
    let showEventStatusItem: Observable<Bool>
    let eventStatusItemLength: Observable<Int>
    let eventStatusItemDetectNotch: Observable<Bool>
    let showWeekNumbers: Observable<Bool>
    let showDeclinedEvents: Observable<Bool>
    let preserveSelectedDate: Observable<Bool>
    let showPastEvents: Observable<Bool>
    let popoverTransparency: Observable<Int>
    let popoverMaterial: Observable<PopoverMaterial>
    let calendarScaling: Observable<Double>

    let dateFormatOptions: Observable<[String]>

    init(
        dateProvider: DateProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter
    ) {

        userDefaults.register(defaults: [
            Prefs.statusItemIconEnabled: true,
            Prefs.statusItemDateEnabled: true,
            Prefs.statusItemDateStyle: 1,
            Prefs.showEventStatusItem: false,
            Prefs.eventStatusItemLength: 18,
            Prefs.eventStatusItemDetectNotch: false,
            Prefs.showWeekNumbers: false,
            Prefs.showDeclinedEvents: false,
            Prefs.preserveSelectedDate: false,
            Prefs.showPastEvents: true,
            Prefs.transparencyLevel: 2,
            Prefs.calendarScaling: 1
        ])

        toggleStatusItemIcon = userDefaults.rx.observer(for: \.statusItemIconEnabled)
        toggleStatusItemDate = userDefaults.rx.observer(for: \.statusItemDateEnabled)
        statusItemDateStyleObserver = userDefaults.rx.observer(for: \.statusItemDateStyle).mapObserver(\.rawValue)
        toggleEventStatusItem = userDefaults.rx.observer(for: \.showEventStatusItem)
        eventStatusItemLengthObserver = userDefaults.rx.observer(for: \.eventStatusItemLength)
        toggleEventStatusItemDetectNotch = userDefaults.rx.observer(for: \.eventStatusItemDetectNotch)
        toggleWeekNumbers = userDefaults.rx.observer(for: \.showWeekNumbers)
        toggleDeclinedEvents = userDefaults.rx.observer(for: \.showDeclinedEvents)
        togglePreserveSelectedDate = userDefaults.rx.observer(for: \.preserveSelectedDate)
        togglePastEvents = userDefaults.rx.observer(for: \.showPastEvents)
        transparencyObserver = userDefaults.rx.observer(for: \.transparencyLevel)
        calendarScalingObserver = userDefaults.rx.observer(for: \.calendarScaling)

        let statusItemIconAndDate = Observable.combineLatest(
            userDefaults.rx.observe(\.statusItemIconEnabled),
            userDefaults.rx.observe(\.statusItemDateEnabled)
        )
        .map { iconEnabled, dateEnabled in
            (iconEnabled || !dateEnabled, dateEnabled)
        }

        showStatusItemIcon = statusItemIconAndDate.map(\.0)
        showStatusItemDate = statusItemIconAndDate.map(\.1)
        statusItemDateStyle = userDefaults.rx.observe(\.statusItemDateStyle).map { DateStyle(rawValue: $0) ?? .none }
        showEventStatusItem = userDefaults.rx.observe(\.showEventStatusItem)
        eventStatusItemLength = userDefaults.rx.observe(\.eventStatusItemLength)
        eventStatusItemDetectNotch = userDefaults.rx.observe(\.eventStatusItemDetectNotch)
        showWeekNumbers = userDefaults.rx.observe(\.showWeekNumbers)
        showDeclinedEvents = userDefaults.rx.observe(\.showDeclinedEvents)
        preserveSelectedDate = userDefaults.rx.observe(\.preserveSelectedDate)
        showPastEvents = userDefaults.rx.observe(\.showPastEvents)
        popoverTransparency = userDefaults.rx.observe(\.transparencyLevel)
        calendarScaling = userDefaults.rx.observe(\.calendarScaling)

        dateFormatOptions = notificationCenter.rx.notification(NSLocale.currentLocaleDidChangeNotification)
            .void()
            .startWith(())
            .map {
                let dateFormatter = DateFormatter(calendar: dateProvider.calendar)
                var options: [String] = []

                for i: UInt in 1...4 {
                    dateFormatter.dateStyle = DateStyle(rawValue: i) ?? .none
                    options.append(dateFormatter.string(from: dateProvider.now))
                }

                return options
            }
            .share(replay: 1)

        popoverMaterial = popoverTransparency.map(PopoverMaterial.init(transparency:))
    }
}
