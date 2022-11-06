//
//  WorkspaceServiceProvider.swift
//  Calendr
//
//  Created by Paker on 21/02/2021.
//

import AppKit.NSWorkspace

protocol WorkspaceServiceProviding {

    var notificationCenter: NotificationCenter { get }

    func urlForApplication(toOpen url: URL) -> URL?
    @discardableResult func open(_ url: URL) -> Bool
}

extension WorkspaceServiceProviding {

    func supports(scheme: String) -> Bool {
        URL(string: scheme).flatMap(urlForApplication(toOpen:)) != nil
    }
}

extension NSWorkspace: WorkspaceServiceProviding { }
