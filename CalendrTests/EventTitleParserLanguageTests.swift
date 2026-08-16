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
        let english = EventTitleDateParser.parse("Meeting tomorrow at 2pm", language: .english)

        #expect(english.dayOffset == 1)
        #expect(english.time == .init(hour: 14, minute: 0))

        // The same English wording means nothing to the Czech parser.
        let czech = EventTitleDateParser.parse("Meeting tomorrow at 2pm", language: .czech)

        #expect(czech.dayOffset == nil)
        #expect(czech.time == nil)
        #expect(czech.tokens.isEmpty)

        let czechInput = EventTitleDateParser.parse("Schůze zítra ve 14", language: .czech)

        #expect(czechInput.dayOffset == 1)
        #expect(czechInput.time == .init(hour: 14, minute: 0))

        let englishReadingCzech = EventTitleDateParser.parse("Schůze zítra ve 14", language: .english)

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

    @Test(arguments: [
        ("Schůze zítra ve 14", "Schůze zitra ve 14"),
        ("Schůze za týden", "Schůze za tyden"),
        ("Schůze příští pátek", "Schůze pristi patek"),
        ("Schůze zítra večer", "Schůze zitra vecer"),
        ("Schůze zítra na 2 týdny", "Schůze zitra na 2 tydny"),
        ("Schůze zítra celý den", "Schůze zitra cely den"),
        ("Schůze zítra v poledne", "Schůze zitra v poledne"),
        ("Schůze zítra o půlnoci", "Schůze zitra o pulnoci"),
    ])
    func testCzechGrammarAcceptsUnaccentedSpelling(_ accented: String, _ unaccented: String) {
        let accentedResult = EventTitleDateParser.parse(accented, language: .czech)
        let unaccentedResult = EventTitleDateParser.parse(unaccented, language: .czech)

        #expect(accentedResult.dayOffset == unaccentedResult.dayOffset)
        #expect(accentedResult.time == unaccentedResult.time)
        #expect(accentedResult.weekday == unaccentedResult.weekday)
        #expect(accentedResult.duration == unaccentedResult.duration)
        #expect(accentedResult.isAllDay == unaccentedResult.isAllDay)
        #expect(accentedResult.tokens.count == unaccentedResult.tokens.count)
        #expect(accentedResult.tokens.isEmpty == false)
    }

    @Test func testPreferredLocalizationUsesUserLanguageSupportedByResourceBundle() {
        let preferredLocalizations = EventTitleParserLanguage.resolvePreferredLocalizations(
            availableLocalizations: ["de", "en", "cs"],
            userLanguages: ["cs-CZ", "en-US"]
        )

        #expect(preferredLocalizations == ["cs"])
    }
}
