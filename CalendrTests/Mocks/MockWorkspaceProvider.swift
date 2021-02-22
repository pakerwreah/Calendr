//
//  MockWorkspaceProvider.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import Foundation
@testable import Calendr

class MockWorkspaceProvider: WorkspaceProviding {

    var m_supportsSchema = false

    func supportsSchema(_ schema: String) -> Bool {
        return m_supportsSchema
    }

    func open(_ url: URL) { }
}
