//
//  SettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 16/01/21.
//

import RxCocoa
import RxSwift

typealias StatusItemSettings = (showIcon: Bool, showDate: Bool)

class SettingsViewModel {

    // Observers
    let toggleStatusItemIcon: AnyObserver<Bool>
    let toggleStatusItemDate: AnyObserver<Bool>
    let transparencyObserver: AnyObserver<Int>

    // Observables
    let statusItemSettings: Observable<StatusItemSettings>
    let transparencyObservable: Observable<Int>
    let materialObservable: Observable<NSVisualEffectView.Material>

    init(userDefaults: UserDefaults = .standard) {

        let statusItemIconBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.statusItemIconEnabled)
        )
        let statusItemDateBehavior = BehaviorSubject(
            value: userDefaults.bool(forKey: Prefs.statusItemDateEnabled)
        )
        let transparencyBehavior = BehaviorSubject(
            value: userDefaults.integer(forKey: Prefs.transparencyLevel)
        )

        toggleStatusItemIcon = statusItemIconBehavior.asObserver()
        toggleStatusItemDate = statusItemDateBehavior.asObserver()
        transparencyObserver = transparencyBehavior.asObserver()

        statusItemSettings = Observable.combineLatest(
            statusItemIconBehavior, statusItemDateBehavior
        )
        .map { iconEnabled, dateEnabled in
            (iconEnabled || !dateEnabled, dateEnabled)
        }
        .do(onNext: { iconEnabled, dateEnabled in
            userDefaults.setValuesForKeys([
                Prefs.statusItemIconEnabled: iconEnabled,
                Prefs.statusItemDateEnabled: dateEnabled
            ])
        })
        .share(replay: 1)

        transparencyObservable = transparencyBehavior
            .do(onNext: {
                userDefaults.setValue($0, forKey: Prefs.transparencyLevel)
            })
            .share(replay: 1)

        materialObservable = transparencyBehavior
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
    }
}
