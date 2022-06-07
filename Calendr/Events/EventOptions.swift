//
//  EventOptions.swift
//  Calendr
//
//  Created by Paker on 21/05/22.
//

import AppKit
import RxSwift

class EventOptions: NSMenu, ObservableConvertibleType {

    enum Action {
        case accept
        case maybe
        case decline
    }

    let actionObservable: Observable<Action>
    private let actionObserver: AnyObserver<Action>

    init(current: EventStatus) {

        (actionObservable, actionObserver) = PublishSubject.pipe()

        super.init(title: "")

        if current != .accepted {
            addOption(.accept)
        }
        if current != .maybe {
            addOption(.maybe)
        }
        if current != .declined {
            addOption(.decline)
        }
    }

    @objc private func triggerAction(_ option: Option) {
        actionObserver.onNext(option.value)
    }

    private func addItem(withTitle string: String, action selector: Selector) {
        addItem(withTitle: string, action: selector, keyEquivalent: "").target = self
    }

    private func addOption(_ action: Action) {
        let option = Option(action: #selector(triggerAction), value: action)
        option.target = self
        addItem(option)
    }

    func asObservable() -> Observable<Action> { actionObservable }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class Option: NSMenuItem {

    let value: EventOptions.Action

    init(action: Selector, value: EventOptions.Action) {
        self.value = value
        super.init(title: value.description, action: action, keyEquivalent: "")
        self.image = value.icon
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension EventOptions.Action {

    var icon: NSImage {
        switch self {
        case .accept:
            return Icons.EventStatus.accepted.with(color: .systemGreen)
        case .maybe:
            return Icons.EventStatus.maybe.with(color: .systemOrange)
        case .decline:
            return Icons.EventStatus.declined.with(color: .systemRed)
        }
    }

    var description: String {
        switch self {
        case .accept:
            return Strings.EventStatus.Action.accept
        case .maybe:
            return Strings.EventStatus.Action.maybe
        case .decline:
            return Strings.EventStatus.Action.decline
        }
    }
}
