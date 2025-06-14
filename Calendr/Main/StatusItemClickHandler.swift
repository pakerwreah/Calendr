//
//  StatusItemClickHandler.swift
//  Calendr
//
//  Created by Paker on 14/06/2025.
//

import AppKit
import RxSwift

/**
 We trigger `left` click on mouse `down` and `right` click on mouse `up` on purpose.
 Mouse down feels faster, but NSMenu.popUp blocks the event chain and causes the button to be stuck in a weird state.
 It's not about the highlight effect, it really gets stuck and we have to click it twice for it to work again.
 **/
class StatusItemClickHandler {
    let leftClick = PublishSubject<Void>()
    let rightClick = PublishSubject<Void>()

    @objc private func action() {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .leftMouseDown:
            self.leftClick.onNext(())
        case .rightMouseUp:
            self.rightClick.onNext(())
        default:
            break
        }
    }

    func add(to control: NSControl) {
        control.sendAction(on: [.leftMouseDown, .rightMouseUp])
        control.target = self
        control.action = #selector(action)
    }
}
