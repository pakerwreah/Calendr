//
//  ReminderOptions.swift
//  Calendr
//
//  Created by Paker on 19/06/2021.
//

import AppKit
import RxSwift

class ReminderOptions: NSMenu {

    enum Action {
        case complete
        case remind(DateComponents)
    }

    let actionObservable: Observable<Action>
    private let actionObserver: AnyObserver<Action>

    private let formatter = RelativeDateTimeFormatter()

    init() {

        (actionObservable, actionObserver) = PublishSubject.pipe()

        super.init(title: "")

        formatter.dateTimeStyle = .named

        addItem(withTitle: Strings.Reminder.Options.complete, action: #selector(completeAction))

        addItem(.separator())

        addRemindOption(.init(minute: 5))
        addRemindOption(.init(minute: 15))
        addRemindOption(.init(minute: 30))
        addRemindOption(.init(hour: 1))
        addRemindOption(.init(day: 1))
    }

    @objc private func completeAction(_ sender: NSMenuItem) {
        actionObserver.onNext(.complete)
    }

    @objc private func remindAction(_ option: Option) {
        actionObserver.onNext(.remind(option.value))
    }

    private func addItem(withTitle string: String, action selector: Selector?) {
        addItem(withTitle: string, action: selector, keyEquivalent: "").target = self
    }

    private func addRemindOption(_ value: DateComponents) {
        let option = Option(
            title: Strings.Reminder.Options.remind(formatter.localizedString(from: value)),
            action: #selector(remindAction),
            value: value
        )
        option.target = self
        addItem(option)
    }

    func asObservable() -> Observable<Action> { actionObservable }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class Option: NSMenuItem {

    let value: DateComponents

    init(title: String, action: Selector, value: DateComponents) {
        self.value = value
        super.init(title: title, action: action, keyEquivalent: "")
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
