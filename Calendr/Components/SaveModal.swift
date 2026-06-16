//
//  SaveModal.swift
//  Calendr
//
//  Created by Paker on 16/06/2026.
//

import AppKit

protocol SaveModal {
    var url: URL? { get }

    func begin() async -> NSApplication.ModalResponse
}

extension NSSavePanel: SaveModal { }

protocol SaveModalFactory {
    func make(for url: URL) -> SaveModal
}
