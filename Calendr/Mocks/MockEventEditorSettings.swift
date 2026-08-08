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

    init(naturalLanguage: Bool = false) {
        naturalLanguageEventInputEnabled = .just(naturalLanguage)
    }
}

#endif
