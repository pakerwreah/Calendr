//
//  EventTitleParserLanguage.swift
//  Calendr
//

import Foundation

enum EventTitleParserLanguage: CaseIterable, Equatable {
    case english
    case czech

    var languageCode: String {
        switch self {
        case .english: "en"
        case .czech: "cs"
        }
    }

    var parser: EventTitleParsing.Type {
        switch self {
        case .english: EnglishEventTitleParser.self
        case .czech: CzechEventTitleParser.self
        }
    }

    init(preferredLocalizations: [String]) {
        self = Self.matching(preferredLocalizations) ?? .english
    }

    static var current: EventTitleParserLanguage {
        .init(preferredLocalizations: preferredLocalizations)
    }

    static var preferredLocalizations: [String] {
        let bundle: Bundle
        #if SWIFT_PACKAGE
            bundle = Bundle.module
        #else
            bundle = Bundle(for: EventTitleParserBundleToken.self)
        #endif
        return resolvePreferredLocalizations(
            availableLocalizations: bundle.localizations,
            userLanguages: Locale.preferredLanguages
        )
    }

    static func resolvePreferredLocalizations(
        availableLocalizations: [String],
        userLanguages: [String]
    ) -> [String] {
        Bundle.preferredLocalizations(
            from: availableLocalizations,
            forPreferences: userLanguages
        )
    }

    static func isSupported(_ preferredLocalizations: [String]) -> Bool {
        matching(preferredLocalizations) != nil
    }

    private static func matching(_ preferredLocalizations: [String]) -> EventTitleParserLanguage? {
        guard let languageCode = preferredLocalizations.first.map(localizationLanguageCode) else {
            return nil
        }
        return allCases.first { $0.languageCode == languageCode }
    }
}

private func localizationLanguageCode(_ identifier: String) -> String {
    identifier
        .replacingOccurrences(of: "_", with: "-")
        .split(separator: "-")
        .first?
        .lowercased() ?? ""
}

private final class EventTitleParserBundleToken {}
