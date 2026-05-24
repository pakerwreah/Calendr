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

    let status: Observable<UpdateStatus> = .just(.initial)
    let error: Observable<UpdateError> = .empty()
    let notificationTap: Observable<NotificationAction> = .empty()

    func start() { }
    func stop() { }
    func checkRelease() { }
    func downloadAndInstall() { }
}

#endif
