//
//  main.swift
//  CalendrLauncher
//
//  Created by Paker on 27/05/2026.
//

import AppKit
import OSLog
import ServiceManagement

let logger = Logger(subsystem: "br.paker.Calendr.launcher", category: "main")

func isTargetApp(at url: URL) -> Bool {
    if BuildConfig.isDebug {
        !url.pathComponents.contains("Applications")
    } else {
        url.pathComponents.contains("Applications")
    }
}

func getRunningApp() -> NSRunningApplication? {
    if let app = NSRunningApplication.runningApplications(withBundleIdentifier: "br.paker.Calendr").first {
        logger.debug("Calendr is already running.")
        return app
    }
    return nil
}

func launchApp() async throws -> NSRunningApplication {

    let apps = NSWorkspace.shared.urlsForApplications(withBundleIdentifier: "br.paker.Calendr")

    guard let appURL = apps.first(where: isTargetApp(at:)) else {
        logger.debug("Invalid URL: Calendr app could not be found.")
        throw URLError(.resourceUnavailable)
    }
    logger.debug("Relaunching Calendr from: \(appURL.path, privacy: .public)")

    return try await NSWorkspace.shared.openApplication(at: appURL, configuration: .init())
}

func main() async throws {

    let app = if let app = getRunningApp() { app } else { try await launchApp() }

    logger.debug("Waiting for termination...")

    var observation: NSKeyValueObservation?
    defer { observation?.invalidate() }

    await withCheckedContinuation { continuation in
        var resumed = false
        observation = app.observe(\.isTerminated, options: [.initial, .new]) { observedApp, change in
            if change.newValue == true && !resumed {
                resumed = true
                logger.debug("Calendr has terminated.")
                continuation.resume()
            }
        }
    }
}

try await main()
