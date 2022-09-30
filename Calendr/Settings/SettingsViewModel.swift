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

        let statusItemIconBehavior = BehaviorSubject(value: userDefaults.statusItemIconEnabled)
        let statusItemDateBehavior = BehaviorSubject(value: userDefaults.statusItemDateEnabled)
        let statusItemDateStyleBehavior = BehaviorSubject(value: DateStyle(rawValue: userDefaults.statusItemDateStyle) ?? .none)
        let showEventStatusItemBehavior = BehaviorSubject(value: userDefaults.showEventStatusItem)
        let eventStatusItemLengthBehavior = BehaviorSubject(value: userDefaults.eventStatusItemLength)
        let eventStatusItemDetectNotchBehavior = BehaviorSubject(value: userDefaults.eventStatusItemDetectNotch)
        let showWeekNumbersBehavior = BehaviorSubject(value: userDefaults.showWeekNumbers)
        let showDeclinedEventsBehavior = BehaviorSubject(value: userDefaults.showDeclinedEvents)
        let preserveSelectedDateBehavior = BehaviorSubject(value: userDefaults.preserveSelectedDate)
        let showPastEventsBehavior = BehaviorSubject(value: userDefaults.showPastEvents)
        let transparencyBehavior = BehaviorSubject(value: userDefaults.transparencyLevel)
        let calendarScalingBehavior = BehaviorSubject(value: userDefaults.calendarScaling)

        toggleStatusItemIcon = statusItemIconBehavior.asObserver()
        toggleStatusItemDate = statusItemDateBehavior.asObserver()
        statusItemDateStyleObserver = statusItemDateStyleBehavior.asObserver()
        toggleEventStatusItem = showEventStatusItemBehavior.asObserver()
        eventStatusItemLengthObserver = eventStatusItemLengthBehavior.asObserver()
        toggleEventStatusItemDetectNotch = eventStatusItemDetectNotchBehavior.asObserver()
        toggleWeekNumbers = showWeekNumbersBehavior.asObserver()
        toggleDeclinedEvents = showDeclinedEventsBehavior.asObserver()
        togglePreserveSelectedDate = preserveSelectedDateBehavior.asObserver()
        togglePastEvents = showPastEventsBehavior.asObserver()
        transparencyObserver = transparencyBehavior.asObserver()
        calendarScalingObserver = calendarScalingBehavior.asObserver()

        let statusItemIconAndDate = Observable.combineLatest(
            statusItemIconBehavior, statusItemDateBehavior
        )
        .map { iconEnabled, dateEnabled in
            (iconEnabled || !dateEnabled, dateEnabled)
        }

        showStatusItemIcon = statusItemIconAndDate.map(\.0)
            .do(onNext: {
                userDefaults.statusItemIconEnabled = $0
            })
            .share(replay: 1)

        showStatusItemDate = statusItemIconAndDate.map(\.1)
            .do(onNext: {
                userDefaults.statusItemDateEnabled = $0
            })
            .share(replay: 1)

        statusItemDateStyle = statusItemDateStyleBehavior
            .do(onNext: {
                userDefaults.statusItemDateStyle = $0.rawValue
            })
            .share(replay: 1)

        showEventStatusItem = showEventStatusItemBehavior
            .do(onNext: {
                userDefaults.showEventStatusItem = $0
            })
            .share(replay: 1)

        eventStatusItemLength = eventStatusItemLengthBehavior
            .do(onNext: {
                userDefaults.eventStatusItemLength = $0
            })
            .share(replay: 1)

        eventStatusItemDetectNotch = eventStatusItemDetectNotchBehavior
            .do(onNext: {
                userDefaults.eventStatusItemDetectNotch = $0
            })
            .share(replay: 1)

        showWeekNumbers = showWeekNumbersBehavior
            .do(onNext: {
                userDefaults.showWeekNumbers = $0
            })
            .share(replay: 1)

        showDeclinedEvents = showDeclinedEventsBehavior
            .do(onNext: {
                userDefaults.showDeclinedEvents = $0
            })
            .share(replay: 1)

        preserveSelectedDate = preserveSelectedDateBehavior
            .do(onNext: {
                userDefaults.preserveSelectedDate = $0
            })
            .share(replay: 1)

        showPastEvents = showPastEventsBehavior
            .do(onNext: {
                userDefaults.showPastEvents = $0
            })
            .share(replay: 1)

        popoverTransparency = transparencyBehavior
            .do(onNext: {
                userDefaults.transparencyLevel = $0
            })
            .share(replay: 1)

        calendarScaling = calendarScalingBehavior
            .do(onNext: {
                userDefaults.calendarScaling = $0
            })
            .share(replay: 1)

        popoverMaterial = transparencyBehavior
            .map { value -> PopoverMaterial in
                [.contentBackground,
                 .sheet,
                 .headerView,
                 .menu,
                 .popover,
                 .hudWindow
                ][value]
            }
            .share(replay: 1)

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
    }
}
