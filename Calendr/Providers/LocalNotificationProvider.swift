//
//  LocalNotificationProvider.swift
//  Calendr
//
//  Created by Paker on 17/08/2024.
//

import UserNotifications
import RxSwift

enum NotificationCategory: String {
    case newVersion
    case updated
}

struct NotificationResponse {
    let category: NotificationCategory
    let actionId: String?
}

protocol LocalNotificationProviding {

    var notificationTap: Observable<NotificationResponse> { get }

    func requestAuthorization() async -> Bool

    func register(_ categories: UNNotificationCategory...) async

    @discardableResult
    func send(id: String, _ content: UNNotificationContent) async -> Bool
}

class LocalNotificationProvider: NSObject, LocalNotificationProviding, UNUserNotificationCenterDelegate {

    private let notificationCenter = UNUserNotificationCenter.current()

    private let notificationTapObserver: AnyObserver<NotificationResponse>
    let notificationTap: Observable<NotificationResponse>

    override init() {
        
        (notificationTap, notificationTapObserver) = PublishSubject.pipe(scheduler: MainScheduler.instance)

        super.init()

        notificationCenter.delegate = self
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    func register(_ categories: UNNotificationCategory...) async {
        var categories = await notificationCenter.notificationCategories()
        categories.forEach { categories.insert($0) }
        notificationCenter.setNotificationCategories(categories)
    }

    func send(id: String, _ content: UNNotificationContent) async -> Bool {
        do {
            try await notificationCenter.add(
                UNNotificationRequest(
                    identifier: id,
                    content: content,
                    trigger: nil
                )
            )
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard
            response.actionIdentifier != UNNotificationDismissActionIdentifier,
            let category = NotificationCategory(rawValue: response.notification.request.content.categoryIdentifier)
        else { return }
        
        let actionId = response.actionIdentifier != UNNotificationDefaultActionIdentifier ? response.actionIdentifier : nil

        notificationTapObserver.onNext(.init(category: category, actionId: actionId))
    }
}

extension UNNotificationCategory {

    convenience init(categoryId: String) {
        self.init(identifier: categoryId, actions: [], intentIdentifiers: [])
    }

    convenience init(categoryId: String, actionId: String, title: String) {
        let install = UNNotificationAction(identifier: actionId, title: title, options: .foreground)
        self.init(identifier: categoryId, actions: [install], intentIdentifiers: [])
    }
}
