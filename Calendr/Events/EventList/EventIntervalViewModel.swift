//
//  EventIntervalViewModel.swift
//  Calendr
//
//  Created by Paker on 24/09/2025.
//

import RxSwift

class EventIntervalViewModel {
    let text: Observable<String>
    let fade: Observable<Bool>

    init(text: Observable<String>, fade: Observable<Bool>) {
        self.text = text
        self.fade = fade
    }
}
