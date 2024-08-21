//
//  Sentry.swift
//  Calendr
//
//  Created by Paker on 15/08/2024.
//

import Sentry

func startSentry() -> Span? {
    guard let dsn = Environment.SENTRY_DSN else { return nil }

    SentrySDK.start { configureSentry(dsn, $0) }

    let transaction = SentrySDK.startTransaction(transactionContext: .appLaunch())

    addSystemUptimeInfo(to: transaction)

    return transaction
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

private func configureSentry(_ dsn: String, _ options: Options) {
    options.dsn = dsn
    options.enableAppHangTracking = false
}

extension TransactionContext {
    static func appLaunch() -> Self { .init(name: "app", operation: "launch", sampled: .yes) }
}
