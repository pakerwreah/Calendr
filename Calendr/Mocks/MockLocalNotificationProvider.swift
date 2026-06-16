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

    private let notificationTapSubject = PublishSubject<NotificationResponse>()
    var notificationTap: Observable<NotificationResponse> { notificationTapSubject.asObservable() }

    var m_requestAuthorization = true
    var spySendNotification: ((_ id: String, UNNotificationContent) -> Bool)?
    var spyRegisteredCategories: [UNNotificationCategory] = []

    func requestAuthorization() async -> Bool {
        m_requestAuthorization
    }

    func register(_ categories: UNNotificationCategory...) {
        spyRegisteredCategories.append(contentsOf: categories)
    }

    @discardableResult
    func send(id: String, _ content: UNNotificationContent) async -> Bool {
        spySendNotification?(id, content) ?? true
    }

    func simulateNotificationTap(_ response: NotificationResponse) {
        notificationTapSubject.onNext(response)
    }
}

#endif
