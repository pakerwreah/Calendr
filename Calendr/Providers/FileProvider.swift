//
//  FileProvider.swift
//  Calendr
//
//  Created by Paker on 16/06/2026.
//

import Foundation

protocol FileProviding {
    var temporaryDirectory: URL { get }

    func url(for directory: FileManager.SearchPathDirectory) -> URL?
    func removeItem(at url: URL) throws
    func trashItem(at url: URL) throws
}

class FileProvider: FileProviding {

    private let fileManager: FileManager = .default

    var temporaryDirectory: URL { fileManager.temporaryDirectory }

    func url(for directory: FileManager.SearchPathDirectory) -> URL? {
        try? fileManager.url(for: directory, in: .localDomainMask, appropriateFor: nil, create: false)
    }

    func removeItem(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    func trashItem(at url: URL) throws {
        try fileManager.trashItem(at: url, resultingItemURL: nil)
    }
}
