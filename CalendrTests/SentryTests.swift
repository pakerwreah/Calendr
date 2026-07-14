//
//  SentryTests.swift
//  CalendrTests
//

import Foundation
import Testing
@testable import Calendr

class SentryTests {

    private let fileManager = FileManager.default
    private var tempDirs: [URL] = []

    deinit {
        for dir in tempDirs {
            try? fileManager.removeItem(at: dir)
        }
        tempDirs.removeAll()
    }

    @Test func testPrepareSentryStorage_shouldCreateDestinationAndMoveOnlySentryEntries() throws {

        let root = makeTempDir()
        let applicationSupport = root.appendingPathComponent("Application Support")
        let caches = root.appendingPathComponent("Caches")

        try fileManager.createDirectory(at: caches, withIntermediateDirectories: true)
        try createDirectory(named: "io.sentry", in: caches)
        try createDirectory(named: "SentryCrash", in: caches)
        try createDirectory(named: "SentryCrashReports", in: caches)
        try Data("installation".utf8).write(to: caches.appendingPathComponent("INSTALLATION"))
        try Data("diagnostic".utf8).write(to: caches.appendingPathComponent("async.log"))
        try Data("other".utf8).write(to: caches.appendingPathComponent("other.cache"))

        let result = try prepareSentryStorage(
            fileManager: fileManager,
            applicationSupportDirectory: applicationSupport,
            cachesDirectory: caches
        )

        let expected = applicationSupport
            .appendingPathComponent("Calendr", isDirectory: true)
            .appendingPathComponent("Sentry", isDirectory: true)
        #expect(result == expected)
        #expect(fileManager.fileExists(atPath: result.path))
        for entry in ["SentryCrash", "SentryCrashReports", "io.sentry"] {
            #expect(!fileManager.fileExists(atPath: caches.appendingPathComponent(entry).path))
            #expect(fileManager.fileExists(atPath: result.appendingPathComponent(entry).path))
            let data = try Data(
                contentsOf: result
                    .appendingPathComponent(entry)
                    .appendingPathComponent("data")
            )
            #expect(data == Data("cached".utf8))
        }
        #expect(!fileManager.fileExists(atPath: caches.appendingPathComponent("INSTALLATION").path))
        let installation = try Data(contentsOf: result.appendingPathComponent("INSTALLATION"))
        #expect(installation == Data("installation".utf8))
        #expect(fileManager.fileExists(atPath: caches.appendingPathComponent("async.log").path))
        #expect(fileManager.fileExists(atPath: caches.appendingPathComponent("other.cache").path))
    }

    @Test func testPrepareSentryStorage_whenRunAgain_shouldRemainIdempotent() throws {

        let root = makeTempDir()
        let applicationSupport = root.appendingPathComponent("Application Support")
        let caches = root.appendingPathComponent("Caches")

        try fileManager.createDirectory(at: caches, withIntermediateDirectories: true)
        try createDirectory(named: "io.sentry", in: caches)

        let first = try prepareSentryStorage(
            fileManager: fileManager,
            applicationSupportDirectory: applicationSupport,
            cachesDirectory: caches
        )
        let second = try prepareSentryStorage(
            fileManager: fileManager,
            applicationSupportDirectory: applicationSupport,
            cachesDirectory: caches
        )

        #expect(first == second)
        #expect(fileManager.fileExists(atPath: second.path))
        #expect(!fileManager.fileExists(atPath: caches.appendingPathComponent("io.sentry").path))
        let data = try Data(
            contentsOf: second
                .appendingPathComponent("io.sentry")
                .appendingPathComponent("data")
        )
        #expect(data == Data("cached".utf8))
    }

    @Test func testPrepareSentryStorage_whenDestinationExists_shouldRemoveLegacyEntry() throws {

        let root = makeTempDir()
        let applicationSupport = root.appendingPathComponent("Application Support")
        let caches = root.appendingPathComponent("Caches")
        let destination = applicationSupport
            .appendingPathComponent("Calendr", isDirectory: true)
            .appendingPathComponent("Sentry", isDirectory: true)

        try fileManager.createDirectory(at: caches, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        try createDirectory(named: "io.sentry", in: caches, contents: "legacy")
        try createDirectory(named: "io.sentry", in: destination, contents: "current")

        let result = try prepareSentryStorage(
            fileManager: fileManager,
            applicationSupportDirectory: applicationSupport,
            cachesDirectory: caches
        )

        #expect(!fileManager.fileExists(atPath: caches.appendingPathComponent("io.sentry").path))
        let data = try Data(
            contentsOf: result
                .appendingPathComponent("io.sentry")
                .appendingPathComponent("data")
        )
        #expect(data == Data("current".utf8))
    }

    private func makeTempDir() -> URL {
        let dir = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        tempDirs.append(dir)
        return dir
    }

    private func createDirectory(
        named name: String,
        in parent: URL,
        contents: String = "cached"
    ) throws {
        let directory = parent.appendingPathComponent(name, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data(contents.utf8).write(to: directory.appendingPathComponent("data"))
    }
}
