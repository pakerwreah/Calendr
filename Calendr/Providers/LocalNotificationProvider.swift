//
//  LocalNotificationProvider.swift
//  Calendr
//
//  Created by Paker on 17/08/2024.
//

import UserNotifications

protocol LocalNotificationProviding {

    var delegate: UNUserNotificationCenterDelegate? { get set }

    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?)

    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void)
}

extension UNUserNotificationCenter: LocalNotificationProviding { }
