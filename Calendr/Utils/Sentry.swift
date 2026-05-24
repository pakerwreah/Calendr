//
//  Sentry.swift
//  Calendr
//
//  Created by Paker on 15/08/2024.
//

import Sentry

func startSentry() -> Span? {
    guard let dsn = AppEnvironment.SENTRY_DSN else { return nil }

    let createCacheResult = Result(catching: createCacheDirectory)
    defer {
        if case .failure(let error) = createCacheResult {
            SentrySDK.capture(error: error)
        }
    }

    SentrySDK.start { options in
        options.dsn = dsn
        options.enableAppHangTracking = false

        if case .success(let cacheDirectoryPath) = createCacheResult {
            options.cacheDirectoryPath = cacheDirectoryPath
        }

        if BuildConfig.isDebug {
            options.sampleRate = 0
        }
    }

    let transaction = SentrySDK.startTransaction(transactionContext: .appLaunch())

    addSystemUptimeInfo(to: transaction)

    return transaction
}

/// Prevent macOS from killing the app under heavy load to purge the caches (0xBADDD15C)
private func createCacheDirectory() throws -> String {
    let fileManager = FileManager.default

    guard let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
        throw .unexpected("Failed to get application support directory")
    }

    let cachesURL = applicationSupport.appending(component: "SentryCaches", directoryHint: .isDirectory)

    if !fileManager.fileExists(atPath: cachesURL.absoluteString) {
        try fileManager.createDirectory(at: cachesURL, withIntermediateDirectories: true)
    }

    return cachesURL.absoluteString
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
