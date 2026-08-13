//
//  GlobalShortcutsViewController.swift
//  Calendr
//
//  Created by Paker on 13/08/2026.
//

import AppKit
import RxSwift
import KeyboardShortcuts

private typealias GlobalShortcuts = Strings.Settings.Keyboard.GlobalShortcuts

class GlobalShortcutsViewController: NSViewController, SettingsUI {

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        title = GlobalShortcuts.title
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setUpContent()
    }

    private lazy var contentView = NSStackView(
        views: [
            makeShortcut(text: GlobalShortcuts.openCalendar, for: .showMainPopover),
            makeShortcut(text: GlobalShortcuts.newEvent, for: .newEvent),
            makeShortcut(text: GlobalShortcuts.newReminder, for: .newReminder),
            makeShortcut(text: GlobalShortcuts.openNextEvent, for: .showNextEventPopover),
            makeShortcut(text: GlobalShortcuts.openNextEventOptions, for: .showNextEventOptions),
            makeShortcut(text: GlobalShortcuts.joinNextEvent, for: .joinNextEvent),
            makeShortcut(text: GlobalShortcuts.openNextReminder, for: .showNextReminderPopover),
            makeShortcut(text: GlobalShortcuts.openNextReminderOptions, for: .showNextReminderOptions),
        ])
        .with(orientation: .vertical)
        .with(alignment: .width)
        .with(insets: .init(top: Constants.contentSpacing))

    private func setUpContent() {

        contentView.setHuggingPriority(.required, for: .vertical)

        view.addSubview(contentView)

        contentView.edges(equalTo: view)
    }

    private func makeShortcut(text: String, for name: KeyboardShortcuts.Name) -> NSView {

        let label = Label(text: text, font: .systemFont(ofSize: 13))

        let recorder = KeyboardShortcuts.RecorderCocoa(for: name)
        recorder.controlSize = .small
        recorder.font = .systemFont(ofSize: 12)
        recorder.setContentHuggingPriority(.required, for: .horizontal)

        return NSStackView(views: [label, recorder])
    }
}

private extension GlobalShortcuts {
    static let newEvent = Strings.Event.Editor.headline
    static let newReminder = Strings.Reminder.Editor.headline
}

extension KeyboardShortcuts.Name {
    static let showMainPopover = Self("showMainPopover")
    static let newEvent = Self("newEvent")
    static let newReminder = Self("newReminder")
    static let showNextEventPopover = Self("showNextEventPopover")
    static let showNextEventOptions = Self("showNextEventOptions")
    static let showNextReminderPopover = Self("showNextReminderPopover")
    static let showNextReminderOptions = Self("showNextReminderOptions")
    static let joinNextEvent = Self("joinNextEvent")
}
