//
//  ThumbnailProviding.swift
//  Calendr
//
//  Created by Paker on 09/09/2026.
//

import Cocoa

protocol ThumbnailProviding {
    func supports(url: URL) -> Bool
    func fetchThumbnail(for url: URL) async -> NSImage?
}
