//
//  EventSearchTests.swift
//  CalendrTests
//
//  Created by Paker on 28/07/2026.
//

import Foundation
import Testing
@testable import Calendr

class EventSearchTests {

    private let event = EventModel.make(
        title: "Budget review",
        location: "Lisbon office",
        notes: "Bring the quarterly report",
        url: URL(string: "https://example.com/agenda"),
        participants: [.make(name: "Renée Martin")],
        tags: ["Work", "Finance"]
    )

    @Test func testSearch_matchesTextInEverySearchableField() {

        for searchTerm in ["budget", "office", "agenda", "quarterly", "renee"] {
            #expect(EventSearch.search(searchTerm, in: event), "Expected \(searchTerm) to match")
        }
    }

    @Test func testSearch_isCaseAndDiacriticInsensitive() {

        #expect(EventSearch.search("BUDGET", in: event))
        #expect(EventSearch.search("RENÉE", in: event))
    }

    @Test func testSearch_withOnlyTags_matchesWhenAllTagsArePresent() {

        #expect(EventSearch.search("#work", in: event))
        #expect(EventSearch.search("#WORK  #finance", in: event))
        #expect(EventSearch.search("#finance #WORK ", in: event))
        #expect(!EventSearch.search("#work #personal", in: event))
    }

    @Test func testSearch_withTagsAndText_requiresBothToMatch() {

        #expect(EventSearch.search("#work quarterly", in: event))
        #expect(!EventSearch.search("#personal quarterly", in: event))
        #expect(!EventSearch.search("#work holiday", in: event))
    }

    @Test func testSearch_withWhitespaceOrEmptyTextMatchesEvent() {

        #expect(EventSearch.search("", in: event))
        #expect(EventSearch.search("   ", in: event))
    }
}
