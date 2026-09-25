//
//  EventTitleParserLanguage.swift
//  Calendr
//

import Foundation

enum EventTitleParserLanguage: String, CaseIterable, Equatable {
    case english = "en"
    case czech = "cs"
    case universal = "*"

    var parser: EventTitleParsing.Type {
        switch self {
            case .english: EnglishEventTitleParser.self
            case .czech: CzechEventTitleParser.self
            case .universal: UniversalEventTitleParser.self
        }
    }

    init(preferredLocalizations: [String]) {
        self = matching(preferredLocalizations) ?? .universal
    }
}

private func matching(_ preferredLocalizations: [String]) -> EventTitleParserLanguage? {

    for languageCode in preferredLocalizations.lazy.map(Localizations.baseLanguageCode) {
        if let language = EventTitleParserLanguage.allCases.first(where: { $0.rawValue == languageCode }) {
            return language
        }
    }
    return nil
}
