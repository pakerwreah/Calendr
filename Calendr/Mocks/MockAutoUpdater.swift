//
//  MockAutoUpdater.swift
//  Calendr
//
//  Created by Paker on 24/05/2026.
//

#if DEBUG

import Foundation
import RxSwift

class MockAutoUpdater: AutoUpdating {

    let status: Observable<UpdateStatus>
    let statusObserver: AnyObserver<UpdateStatus>

    let error: Observable<UpdateError>
    let errorObserver: AnyObserver<UpdateError>

    let notificationTap: Observable<NotificationAction>
    let notificationTapObserver: AnyObserver<NotificationAction>

    var didStart: (() -> Void)?
    var didStop: (() -> Void)?

    init() {
        (status, statusObserver) = BehaviorSubject.pipe(value: .initial)
        (error, errorObserver) = PublishSubject.pipe()
        (notificationTap, notificationTapObserver) = PublishSubject.pipe()
    }

    func start() { didStart?() }
    func stop() { didStop?() }
    func checkRelease() { }
    func downloadAndInstall() { }
}

#endif
