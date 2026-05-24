//
//  AppCacheCleaner.swift
//  Calendr
//
//  Created by Paker on 24/05/2026.
//

import AppKit
import Sentry

/// Prevent macOS from killing the app under heavy load to purge the caches (0xBADDD15C)
class AppCacheCleaner {
    private let fileManager = FileManager.default
    private var task: Task<Void, Error>?

    func schedule() {
        task?.cancel()
        task = Task { @MainActor in
            try await Task.sleep(for: .seconds(5))
            if NSApp.popovers.isEmpty {
                delete()
            }
        }
    }

    func cancel() {
        task?.cancel()
    }

    func delete() {
        guard
            BuildConfig.isSandboxed, // just to be safe
            let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        else { return }

        do {
            try fileManager.removeItem(at: cachesURL)
            try fileManager.createDirectory(at: cachesURL, withIntermediateDirectories: true)
        } catch {
            SentrySDK.capture(error: error)
        }
    }
}
