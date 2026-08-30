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
