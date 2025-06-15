//
//  MockWorkspaceServiceProvider.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import Foundation
@testable import Calendr
import UniformTypeIdentifiers

class MockWorkspaceServiceProvider: WorkspaceServiceProviding {
    let userDefaults: UserDefaults
    let dateProvider: DateProviding
    let calendarAppProvider: CalendarAppProviding
    let notificationCenter: NotificationCenter

    init (
        userDefaults: UserDefaults? = nil,
        dateProvider: DateProviding? = nil,
        calendarAppProvider: CalendarAppProviding? = nil,
        notificationCenter: NotificationCenter? = nil
    ) {
        self.userDefaults = userDefaults ?? .init(suiteName: String(describing: Self.self))!
        self.dateProvider = dateProvider ?? MockDateProvider()
        self.calendarAppProvider = calendarAppProvider ?? MockCalendarAppProvider()
        self.notificationCenter = notificationCenter ?? .init()
    }

    var m_urlForApplicationToOpenURL: URL?
    var m_urlForApplicationToOpenContentType: URL?

    var m_urlsForApplicationsToOpenURL: [URL] = []
    var m_urlsForApplicationsToOpenContentType: [URL] = []

    var didOpenURL: ((URL) -> Void)?
    var didOpenEvent: ((EventModel) -> Void)?
    var didOpenDate: ((Date, CalendarViewMode) -> Void)?
    var didOpenURLWithApplication: ((URL, _ applicationURL: URL?) -> Void)?

    func urlForApplication(toOpen url: URL) -> URL? { m_urlForApplicationToOpenURL }

    func urlsForApplications(toOpen url: URL) -> [URL] { m_urlsForApplicationsToOpenURL }

    func urlForApplication(toOpen contentType: UTType) -> URL? { m_urlForApplicationToOpenContentType }

    func urlsForApplications(toOpen contentType: UTType) -> [URL] { m_urlsForApplicationsToOpenContentType }

    func open(_ url: URL) -> Bool {
        didOpenURL?(url)
        return true
    }

    func open(_ url: URL, withApplicationAt applicationURL: URL) {
        didOpenURLWithApplication?(url, applicationURL)
    }

    func open(_ event: EventModel) {
        didOpenEvent?(event)
    }

    func open(_ date: Date, mode: CalendarViewMode) {
        didOpenDate?(date, mode)
    }
}
