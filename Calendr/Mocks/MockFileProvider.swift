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

    func url(for directory: FileManager.SearchPathDirectory) -> URL? {
        spyUrlForDirectory?(directory)
    }

    func removeItem(at url: URL) throws {
        try spyRemoveItem?(url)
    }

    func trashItem(at url: URL) throws {
        try spyTrashItem?(url)
    }
}
