//
//  MockEventEditorSettings.swift
//  Calendr
//
//  Created by Paker on 08/08/2026.
//

#if DEBUG

import Foundation
import RxSwift

class MockEventEditorSettings: EventEditorSettings {

    let naturalLanguageEventInputEnabled: Observable<Bool>
    let naturalLanguageEventInputLanguage: Observable<EventTitleParserLanguage>

    init(
        naturalLanguage: Bool = false,
        language: EventTitleParserLanguage = .english
    ) {
        naturalLanguageEventInputEnabled = .just(naturalLanguage)
        naturalLanguageEventInputLanguage = .just(language)
    }
}

#endif
