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
    NSRunningApplication.runningApplications(withBundleIdentifier: "br.paker.Calendr").first
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

    logger.debug("Calendr launched. Monitoring for termination...")

    var observation: NSKeyValueObservation?
    defer { observation?.invalidate() }

    await withCheckedContinuation { continuation in
        observation = app.observe(\.isTerminated, options: [.initial, .new]) { observedApp, change in
            if change.newValue == true {
                logger.debug("Calendr has terminated.")
                continuation.resume()
            }
        }
    }
}

UserDefaults.standard.register(defaults: [
    "launch_delay": 2
])

let delay = UserDefaults.standard.integer(forKey: "launch_delay")

if delay <= 0 {
    logger.debug("Calendr launcher stopped")
    try await Task.sleep(for: .seconds(999999999))
    exit(EXIT_SUCCESS)
}

logger.debug("Calendr launcher started. Waiting \(delay) second(s)...")

try await Task.sleep(for: .seconds(delay))

try await main()
