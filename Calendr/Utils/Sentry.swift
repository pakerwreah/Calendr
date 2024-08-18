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
    return SentrySDK.startTransaction(transactionContext: .appLaunch)
}

private func configureSentry(_ dsn: String, _ options: Options) {
    options.dsn = dsn
    options.enableAppHangTracking = false
}

extension TransactionContext {
    static let appLaunch = TransactionContext(name: "app", operation: "launch", sampled: .yes)
}
