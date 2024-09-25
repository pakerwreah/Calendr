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

    let notificationCenter: NotificationCenter = .init()

    var m_urlForApplicationToOpenURL: URL?
    var m_urlForApplicationToOpenContentType: URL?

    var m_urlsForApplicationsToOpenURL: [URL] = []
    var m_urlsForApplicationsToOpenContentType: [URL] = []

    var didOpen: ((URL) -> Void)?

    func urlForApplication(toOpen url: URL) -> URL? { m_urlForApplicationToOpenURL }

    func urlsForApplications(toOpen url: URL) -> [URL] { m_urlsForApplicationsToOpenURL }

    func urlForApplication(toOpen contentType: UTType) -> URL? { m_urlForApplicationToOpenContentType }

    func urlsForApplications(toOpen contentType: UTType) -> [URL] { m_urlsForApplicationsToOpenContentType }

    func open(_ url: URL) -> Bool { didOpen?(url); return true }
}
