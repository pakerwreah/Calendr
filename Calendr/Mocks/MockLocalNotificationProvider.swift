//
//  MockLocalNotificationProvider.swift
//  Calendr
//
//  Created by Paker on 18/08/2024.
//

#if DEBUG

import Foundation
import UserNotifications
import RxSwift

class MockLocalNotificationProvider: LocalNotificationProviding {

    var notificationTap: Observable<Identifier> = .empty()

    func requestAuthorization() async -> Bool {
        return true
    }

    func register(category: UNNotificationCategory) async { }

    func send(id: String, _ content: UNNotificationContent) async -> Bool {
        return true
    }
}

#endif
