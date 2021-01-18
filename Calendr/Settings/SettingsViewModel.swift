//
//  SettingsViewModel.swift
//  Calendr
//
//  Created by Paker on 16/01/21.
//

import RxCocoa
import RxSwift

class SettingsViewModel {

    // Observers
    let toggleStatusItemIcon: AnyObserver<Bool>
    let toggleStatusItemDate: AnyObserver<Bool>

    // Observables
    let statusItemSettings: Observable<(showIcon: Bool, showDate: Bool)>

    init(userDefaults: UserDefaults = .standard) {

        let statusItemIconBehavior = BehaviorSubject(value: userDefaults.bool(forKey: Prefs.statusItemIconEnabled))
        let statusItemDateBehavior = BehaviorSubject(value: userDefaults.bool(forKey: Prefs.statusItemDateEnabled))

        toggleStatusItemIcon = statusItemIconBehavior.asObserver()
        toggleStatusItemDate = statusItemDateBehavior.asObserver()

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
    }
}
