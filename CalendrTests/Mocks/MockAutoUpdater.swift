//
//  MockAutoUpdater.swift
//  Calendr
//
//  Created by Paker on 24/05/2026.
//

import Foundation
import RxSwift
@testable import Calendr

class MockAutoUpdater: AutoUpdating {

    let status: Observable<UpdateStatus> = .just(.initial)
    let error: Observable<UpdateError> = .empty()
    let notificationTap: Observable<NotificationAction> = .empty()

    var didStart: (() -> Void)?
    var didStop: (() -> Void)?

    func start() { didStart?() }
    func stop() { didStop?() }
    func checkRelease() { }
    func downloadAndInstall() { }
}
