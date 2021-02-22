//
//  WorkspaceProvider.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import AppKit.NSWorkspace

protocol WorkspaceProviding {

    func supportsSchema(_ schema: String) -> Bool
    func open(_ url: URL)
}

class WorkspaceProvider: WorkspaceProviding {

    func supportsSchema(_ schema: String) -> Bool {
        URL(string: schema).map(NSWorkspace.shared.urlForApplication(toOpen:)) != nil
    }

    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}
