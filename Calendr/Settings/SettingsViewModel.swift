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
}

protocol CalendarSettings {
    var showWeekNumbers: Observable<Bool> { get }
    var calendarScaling: Observable<Double> { get }
}

protocol PopoverSettings {
    var popoverMaterial: Observable<PopoverMaterial> { get }
}

protocol EventListSettings: PopoverSettings {
    var showPastEvents: Observable<Bool> { get }
}

protocol NextEventSettings {
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
            Prefs.showPastEvents: true,
            Prefs.transparencyLevel: 2,
            Prefs.calendarScaling: 1
        ])

        let statusItemIconBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.statusItemIconEnabled)
        )
        let statusItemDateBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.statusItemDateEnabled)
        )
        let statusItemDateStyleBehavior = BehaviorSubject(
            value: DateStyle(rawValue: UInt(userDefaults.integer(forKey: Prefs.statusItemDateStyle))) ?? .none
        )
        let showEventStatusItemBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.showEventStatusItem)
        )
        let eventStatusItemLengthBehavior = BehaviorSubject(
            value: userDefaults.integer(forKey: Prefs.eventStatusItemLength)
        )
        let eventStatusItemDetectNotchBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.eventStatusItemDetectNotch)
        )
        let showWeekNumbersBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.showWeekNumbers)
        )
        let showPastEventsBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.showPastEvents)
        )
        let transparencyBehavior = BehaviorSubject(
            value: userDefaults.integer(forKey: Prefs.transparencyLevel)
        )
        let calendarScalingBehavior = BehaviorSubject(
            value: userDefaults.double(forKey: Prefs.calendarScaling)
        )

        toggleStatusItemIcon = statusItemIconBehavior.asObserver()
        toggleStatusItemDate = statusItemDateBehavior.asObserver()
        statusItemDateStyleObserver = statusItemDateStyleBehavior.asObserver()
        toggleEventStatusItem = showEventStatusItemBehavior.asObserver()
        eventStatusItemLengthObserver = eventStatusItemLengthBehavior.asObserver()
        toggleEventStatusItemDetectNotch = eventStatusItemDetectNotchBehavior.asObserver()
        toggleWeekNumbers = showWeekNumbersBehavior.asObserver()
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
                userDefaults.setValue($0, forKey: Prefs.statusItemIconEnabled)
            })
            .share(replay: 1)

        showStatusItemDate = statusItemIconAndDate.map(\.1)
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.statusItemDateEnabled)
            })
            .share(replay: 1)

        statusItemDateStyle = statusItemDateStyleBehavior
            .do(onNext: {
                userDefaults.setValue($0.rawValue, forKey: Prefs.statusItemDateStyle)
            })
            .share(replay: 1)

        showEventStatusItem = showEventStatusItemBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.showEventStatusItem)
            })
            .share(replay: 1)

        eventStatusItemLength = eventStatusItemLengthBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.eventStatusItemLength)
            })
            .share(replay: 1)

        eventStatusItemDetectNotch = eventStatusItemDetectNotchBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.eventStatusItemDetectNotch)
            })
            .share(replay: 1)

        showWeekNumbers = showWeekNumbersBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.showWeekNumbers)
            })
            .share(replay: 1)

        showPastEvents = showPastEventsBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.showPastEvents)
            })
            .share(replay: 1)

        popoverTransparency = transparencyBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.transparencyLevel)
            })
            .share(replay: 1)

        calendarScaling = calendarScalingBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.calendarScaling)
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
