//
//  Sentry.swift
//  Calendr
//
//  Created by Paker on 15/08/2024.
//

import Foundation
import Sentry

private let legacySentryCacheEntries = [
    "INSTALLATION",
    "SentryCrash",
    "SentryCrashReports",
    "io.sentry",
]

func startSentry() -> Span? {
    guard let dsn = AppEnvironment.SENTRY_DSN else { return nil }
    guard let storageDirectory = sentryStorageDirectory() else { return nil }

    SentrySDK.start { options in
        options.dsn = dsn
        options.enableAppHangTracking = false
        options.cacheDirectoryPath = storageDirectory.path

        if BuildConfig.isDebug {
            options.sampleRate = 0
        }
    }

    let transaction = SentrySDK.startTransaction(transactionContext: .appLaunch())

    addSystemUptimeInfo(to: transaction)

    return transaction
}

private func sentryStorageDirectory() -> URL? {
    let fileManager = FileManager.default

    guard
        let applicationSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first,
        let cachesDirectory = fileManager.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first
    else {
        return nil
    }

    return try? prepareSentryStorage(
        fileManager: fileManager,
        applicationSupportDirectory: applicationSupportDirectory,
        cachesDirectory: cachesDirectory
    )
}

func prepareSentryStorage(
    fileManager: FileManager,
    applicationSupportDirectory: URL,
    cachesDirectory: URL
) throws -> URL {
    var storageDirectory = applicationSupportDirectory
        .appendingPathComponent("Calendr", isDirectory: true)
        .appendingPathComponent("Sentry", isDirectory: true)

    try fileManager.createDirectory(
        at: storageDirectory,
        withIntermediateDirectories: true
    )

    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    try? storageDirectory.setResourceValues(resourceValues)

    for entry in legacySentryCacheEntries {
        let source = cachesDirectory.appendingPathComponent(entry)
        guard fileManager.fileExists(atPath: source.path) else { continue }

        let destination = storageDirectory.appendingPathComponent(entry)
        if !fileManager.fileExists(atPath: destination.path),
           (try? fileManager.moveItem(at: source, to: destination)) != nil {
            continue
        }

        try? fileManager.removeItem(at: source)
    }

    return storageDirectory
}

/**
 * Investigating why some `app launch` transactions are taking so long.
 * Trying to see if that's because of high cpu load when user logs in.
 * Ideally we should get the `login_uptime`, but we can't because of `sandbox`.
 */
private func addSystemUptimeInfo(to transaction: Span) {
    /// This is searchable, but not yet suggested in the filter input.
    /// i.e. `measurements.system_uptime:<60k` (less than 1min)
    transaction.setMeasurement(
        name: "system_uptime",
        value: NSNumber(value: ProcessInfo.processInfo.systemUptime),
        unit: MeasurementUnitDuration.second
    )
}

extension TransactionContext {
    static func appLaunch() -> Self {
        .init(name: "app", operation: "launch", sampled: .yes, sampleRate: nil, sampleRand: nil)
    }
}
