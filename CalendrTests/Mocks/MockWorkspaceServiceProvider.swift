//
//  MockWorkspaceServiceProvider.swift
//  CalendrTests
//
//  Created by Paker on 21/02/2021.
//

import Foundation
@testable import Calendr

class MockWorkspaceServiceProvider: WorkspaceServiceProviding {

    var m_supportsScheme = false

    func supports(scheme: String) -> Bool {
        return m_supportsScheme
    }

    func open(_ url: URL) { }
}
