//
//  MockFileProvider.swift
//  Calendr
//
//  Created by Paker on 16/06/2026.
//

import Foundation

class MockFileProvider: FileProviding {

    let temporaryDirectory: URL = .temporaryDirectory

    var spyUrlForDirectory: ((FileManager.SearchPathDirectory) -> URL?)?
    var spyRemoveItem: ((URL) throws -> Void)?
    var spyTrashItem: ((URL) throws -> Void)?

    var spyResolveSecurityScopedURL: ((Data) -> (url: URL?, isStale: Bool))?
    var spyBookmarkData: ((URL) throws -> Data)?
    var spyStartAccessing: ((URL) -> Bool)?
    var spyStopAccessing: ((URL) -> Void)?

    func url(for directory: FileManager.SearchPathDirectory) -> URL? {
        spyUrlForDirectory?(directory)
    }

    func removeItem(at url: URL) throws {
        try spyRemoveItem?(url)
    }

    func trashItem(at url: URL) throws {
        try spyTrashItem?(url)
    }

    func resolveSecurityScopedURL(from bookmark: Data, isStale: inout Bool) -> URL? {
        guard let result = spyResolveSecurityScopedURL?(bookmark) else { return nil }
        isStale = result.isStale
        return result.url
    }

    func bookmarkData(for url: URL) throws -> Data {
        try spyBookmarkData?(url) ?? Data()
    }

    func startAccessingSecurityScopedResource(_ url: URL) -> Bool {
        spyStartAccessing?(url) ?? false
    }

    func stopAccessingSecurityScopedResource(_ url: URL) {
        spyStopAccessing?(url)
    }
}
