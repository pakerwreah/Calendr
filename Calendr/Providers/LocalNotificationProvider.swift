//
//  LocalNotificationProvider.swift
//  Calendr
//
//  Created by Paker on 17/08/2024.
//

import UserNotifications
import RxSwift

protocol LocalNotificationProviding {

    typealias Identifier = String

    var notificationTap: Observable<Identifier> { get }

    func requestAuthorization() async -> Bool

    func register(category: UNNotificationCategory) async

    func send(id: String, _ content: UNNotificationContent) async -> Bool
}

class LocalNotificationProvider: NSObject, LocalNotificationProviding, UNUserNotificationCenterDelegate {

    private let notificationCenter = UNUserNotificationCenter.current()

    private let notificationTapObserver: AnyObserver<Identifier>
    let notificationTap: Observable<Identifier>

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

    func register(category: UNNotificationCategory) async {
        var categories = await notificationCenter.notificationCategories()
        categories.insert(category)
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
        notificationTapObserver.onNext(response.actionIdentifier)
    }
}

extension UNNotificationCategory {

    convenience init(categoryId: String, actionId: String, title: String) {
        let install = UNNotificationAction(identifier: actionId, title: title, options: .foreground)
        self.init(identifier: categoryId, actions: [install], intentIdentifiers: [])
    }
}

extension UNNotificationContent {
    
    static func message(_ text: String) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = text
        content.sound = .default
        return content
    }
}
