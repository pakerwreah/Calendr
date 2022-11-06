//
//  MockWorkspaceServiceProvider.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import Foundation
@testable import Calendr

class MockWorkspaceServiceProvider: WorkspaceServiceProviding {

    let notificationCenter: NotificationCenter = .init()

    var m_urlForApplication: URL?
    var didOpen: ((URL) -> Void)?

    func urlForApplication(toOpen url: URL) -> URL? { m_urlForApplication }
    func open(_ url: URL) -> Bool { didOpen?(url); return true }
}
