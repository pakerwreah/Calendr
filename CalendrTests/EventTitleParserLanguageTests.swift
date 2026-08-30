//
//  EventTitleParserLanguageTests.swift
//  CalendrTests
//

import Testing
@testable import Calendr

struct EventTitleParserLanguageTests {

    @Test(arguments: ["en", "en-GB", "en_US"])
    func testEnglishLocalizationSelectsEnglishParser(_ localization: String) {
        #expect(EventTitleParserLanguage(preferredLocalizations: [localization]) == .english)
    }

    @Test(arguments: ["cs", "cs-CZ", "cs_CZ"])
    func testCzechLocalizationSelectsCzechParser(_ localization: String) {
        #expect(EventTitleParserLanguage(preferredLocalizations: [localization]) == .czech)
    }

    @Test func testUnsupportedLocalizationFallsBackToEnglishParser() {
        #expect(EventTitleParserLanguage(preferredLocalizations: ["de-DE"]) == .english)
    }

    @Test func testEachLanguageResolvesToItsOwnParser() {
        #expect(EventTitleParserLanguage.english.parser == EnglishEventTitleParser.self)
        #expect(EventTitleParserLanguage.czech.parser == CzechEventTitleParser.self)
    }

    @Test func testLanguagesDoNotShareVocabulary() {
        let english = EventTitleParser.parse("Meeting tomorrow at 2pm", language: .english)

        #expect(english.dayOffset == 1)
        #expect(english.time == .init(hour: 14, minute: 0))

        // The same English wording means nothing to the Czech parser.
        let czech = EventTitleParser.parse("Meeting tomorrow at 2pm", language: .czech)

        #expect(czech.dayOffset == nil)
        #expect(czech.time == nil)
        #expect(czech.tokens.isEmpty)

        let czechInput = EventTitleParser.parse("Schůze zítra ve 14", language: .czech)

        #expect(czechInput.dayOffset == 1)
        #expect(czechInput.time == .init(hour: 14, minute: 0))

        let englishReadingCzech = EventTitleParser.parse("Schůze zítra ve 14", language: .english)

        #expect(englishReadingCzech.dayOffset == nil)
        #expect(englishReadingCzech.time == nil)
    }

    @Test func testEverySupportedLanguageIsRecognizedByItsLanguageCode() {
        for language in EventTitleParserLanguage.allCases {
            #expect(EventTitleParserLanguage.isSupported([language.languageCode]))
            #expect(EventTitleParserLanguage(preferredLocalizations: [language.languageCode]) == language)
        }
    }

    @Test func testUnsupportedLocalizationIsNotReportedAsSupported() {
        #expect(EventTitleParserLanguage.isSupported(["de"]) == false)
        #expect(EventTitleParserLanguage.isSupported([]) == false)
    }
}
