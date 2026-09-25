//
//  EventTitleParserLanguage.swift
//  Calendr
//

import Foundation

enum EventTitleParserLanguage: CaseIterable, Equatable {
    case english
    case czech
    case universal

    var languageCode: String {
        switch self {
            case .english: "en"
            case .czech: "cs"
            case .universal: "*"
        }
    }

    var parser: EventTitleParsing.Type {
        switch self {
            case .english: EnglishEventTitleParser.self
            case .czech: CzechEventTitleParser.self
            case .universal: UniversalEventTitleParser.self
        }
    }

    init(preferredLocalizations: [String]) {
        // FIXME: remove after finishing tests
        if BuildConfig.isDebug, !BuildConfig.isTesting {
            self = .universal
        }
        // FIXME: fallback to .universal after finishing tests
        self = Self.matching(preferredLocalizations) ?? .english
    }

    static var current: EventTitleParserLanguage {
        .init(preferredLocalizations: Localizations.preferredLocalizations)
    }

    static func isSupported(_ preferredLocalizations: [String]) -> Bool {
        matching(preferredLocalizations) != nil
    }

    private static func matching(_ preferredLocalizations: [String]) -> EventTitleParserLanguage? {

        for languageCode in preferredLocalizations.lazy.map(Localizations.baseLanguageCode) {
            if let language = allCases.first(where: { $0.languageCode == languageCode }) {
                return language
            }
        }
        return nil
    }
}
