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

    func register(_ categories: UNNotificationCategory...)

    @discardableResult
    func send(id: String, _ content: UNNotificationContent) async -> Bool
}

extension LocalNotificationProviding {
    
    func send(id: String, _ content: UNNotificationContent) {
        Task {
            await send(id: id, content)
        }
    }
}

class LocalNotificationProvider: NSObject, LocalNotificationProviding, UNUserNotificationCenterDelegate {

    private let notificationCenter = UNUserNotificationCenter.current()

    private let notificationTapObserver: AnyObserver<NotificationResponse>
    let notificationTap: Observable<NotificationResponse>

    private var categories = Set<UNNotificationCategory>()

    override init() {

        (notificationTap, notificationTapObserver) = PublishSubject.pipe(on: MainScheduler.instance)

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

    func register(_ categories: UNNotificationCategory...) {

        for category in categories {
            self.categories.insert(category)
        }
        notificationCenter.setNotificationCategories(self.categories)
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
        self.init(identifier: categoryId, actions: [], intentIdentifiers: [], options: .hiddenPreviewsShowTitle)
    }

    convenience init(categoryId: String, actionId: String, title: String) {
        let install = UNNotificationAction(identifier: actionId, title: title, options: .foreground)
        self.init(identifier: categoryId, actions: [install], intentIdentifiers: [], options: .hiddenPreviewsShowTitle)
    }
}
