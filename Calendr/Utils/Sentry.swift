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

    if ProcessInfo.processInfo.architecture == .x86_64 {
        options.appHangTimeoutInterval += 1
    }

    options.beforeSend = { event in
        if (event.exceptions?.first?.type == "App Hanging") {
            event.level = .debug
        }
        return event
    }
}

/// Prevents reporting false hangings for known blocking operations (i.e. context menus)
func blocking<T>(operation: () -> T) -> T {
    SentrySDK.pauseAppHangTracking()
    defer { SentrySDK.resumeAppHangTracking() }
    return operation()
}

extension TransactionContext {
    static let appLaunch = TransactionContext(name: "app", operation: "launch", sampled: .yes)
}
