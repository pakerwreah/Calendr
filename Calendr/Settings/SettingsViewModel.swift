//
//  SettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 16/01/21.
//

import RxCocoa
import RxSwift

protocol StatusItemSettings {
    var showStatusItemIcon: Observable<Bool> { get }
    var showStatusItemDate: Observable<Bool> { get }
    var statusItemDateStyle: Observable<DateFormatter.Style> { get }
}

protocol CalendarSettings {
    var showWeekNumbers: Observable<Bool> { get }
}

protocol EventSettings {
    var showPastEvents: Observable<Bool> { get }
}

protocol NextEventSettings {
    var showEventStatusItem: Observable<Bool> { get }
}

class SettingsViewModel: StatusItemSettings, NextEventSettings, CalendarSettings, EventSettings  {

    // Observers
    let toggleStatusItemIcon: AnyObserver<Bool>
    let toggleStatusItemDate: AnyObserver<Bool>
    let statusItemDateStyleObserver: AnyObserver<DateFormatter.Style>
    let toggleEventStatusItem: AnyObserver<Bool>
    let toggleWeekNumbers: AnyObserver<Bool>
    let togglePastEvents: AnyObserver<Bool>
    let transparencyObserver: AnyObserver<Int>

    // Observables
    var showStatusItemIcon: Observable<Bool>
    var showStatusItemDate: Observable<Bool>
    var statusItemDateStyle: Observable<DateFormatter.Style>
    let showEventStatusItem: Observable<Bool>
    let showWeekNumbers: Observable<Bool>
    let showPastEvents: Observable<Bool>
    let popoverTransparency: Observable<Int>
    let popoverMaterial: Observable<NSVisualEffectView.Material>

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
            Prefs.showWeekNumbers: false,
            Prefs.showPastEvents: true,
            Prefs.transparencyLevel: 2
        ])

        let statusItemIconBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.statusItemIconEnabled)
        )
        let statusItemDateBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.statusItemDateEnabled)
        )
        let statusItemDateStyleBehavior = BehaviorSubject(
            value: DateFormatter.Style(rawValue: UInt(userDefaults.integer(forKey: Prefs.statusItemDateStyle))) ?? .none
        )
        let showEventStatusItemBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.showEventStatusItem)
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

        toggleStatusItemIcon = statusItemIconBehavior.asObserver()
        toggleStatusItemDate = statusItemDateBehavior.asObserver()
        statusItemDateStyleObserver = statusItemDateStyleBehavior.asObserver()
        toggleEventStatusItem = showEventStatusItemBehavior.asObserver()
        toggleWeekNumbers = showWeekNumbersBehavior.asObserver()
        togglePastEvents = showPastEventsBehavior.asObserver()
        transparencyObserver = transparencyBehavior.asObserver()

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

        popoverMaterial = transparencyBehavior
            .map { value -> NSVisualEffectView.Material in
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
            .toVoid()
            .startWith(())
            .map {
                let dateFormatter = DateFormatter(locale: dateProvider.calendar.locale)
                var options: [String] = []

                for i: UInt in 1...4 {
                    dateFormatter.dateStyle = DateFormatter.Style(rawValue: i) ?? .none
                    options.append(dateFormatter.string(from: dateProvider.now))
                }

                return options
            }
            .share(replay: 1)
    }
}
