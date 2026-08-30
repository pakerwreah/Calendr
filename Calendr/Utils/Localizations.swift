//
//  Localizations.swift
//  Calendr
//
//  Created by Paker on 30/08/2026.
//

import Foundation

enum Localizations {
    private final class PrefsBundleToken {}

    static var preferredLocalizations: [String] {
        let bundle: Bundle
        #if SWIFT_PACKAGE
            bundle = Bundle.module
        #else
            bundle = Bundle(for: PrefsBundleToken.self)
        #endif

        return Bundle.preferredLocalizations(
            from: bundle.localizations,
            forPreferences: Locale.preferredLanguages
        )
    }

    static func baseLanguageCode(_ identifier: String) -> String {
        identifier
            .prefix(while: \.isLetter)
            .lowercased()
    }
}
