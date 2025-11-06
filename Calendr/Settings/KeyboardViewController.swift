//
//  KeyboardViewController.swift
//  Calendr
//
//  Created by Paker on 20/07/24.
//

import Cocoa
import RxSwift
import KeyboardShortcuts

class KeyboardViewController: NSViewController, SettingsUI {

    private let disposeBag = DisposeBag()

    typealias LocalShortcuts = Strings.Settings.Keyboard.LocalShortcuts
    typealias GlobalShortcuts = Strings.Settings.Keyboard.GlobalShortcuts

    private var commandCharWidth = NSLayoutGuide()

    init() {
        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.Keyboard.view)
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        view.addLayoutGuide(commandCharWidth)

        let stackView = NSStackView(
            views: Sections.create([
                makeSection(title: LocalShortcuts.title, content: localContent),
                makeSection(title: GlobalShortcuts.title, content: globalContent),
            ])
            .disposed(by: disposeBag)
        )
        .with(spacing: Constants.contentSpacing)
        .with(orientation: .vertical)

        view.addSubview(stackView)

        stackView.edges(equalTo: view, margins: .init(bottom: 1))

        Scaling.observable
            .map { CGFloat(16 * $0) }
            .bind(to: commandCharWidth.width(equalTo: 1).rx.constant)
            .disposed(by: disposeBag)
    }

    private lazy var localContent: NSView = {

        return NSStackView(views: [
            makeLocalShortcut(text: LocalShortcuts.prevDate, keys: "←"),
            makeLocalShortcut(text: LocalShortcuts.nextDate, keys: "→"),
            makeLocalShortcut(text: LocalShortcuts.prevWeek, keys: "↑"),
            makeLocalShortcut(text: LocalShortcuts.nextWeek, keys: "↓"),
            makeLocalShortcut(text: LocalShortcuts.prevMonth, keys: "⌘ ←", "⌘ ↑"),
            makeLocalShortcut(text: LocalShortcuts.nextMonth, keys: "⌘ →", "⌘ ↓"),
            makeLocalShortcut(text: LocalShortcuts.currDate, keys: "⌫"),
            makeLocalShortcut(text: LocalShortcuts.openDate, keys: "↵"),
            makeLocalShortcut(text: LocalShortcuts.showWeekNumbers, keys: "⌥ W"),
            makeLocalShortcut(text: LocalShortcuts.showDeclinedEvents, keys: "⌥ D"),
            makeLocalShortcut(text: LocalShortcuts.pinCalendar, keys: "⌘ P"),
            makeLocalShortcut(text: LocalShortcuts.settings, keys: "⌘ ,"),
            makeLocalShortcut(text: LocalShortcuts.quit, keys: "⌘ Q"),
        ])
        .with(orientation: .vertical)
    }()

    private func makeLocalShortcut(text: String, keys: String...) -> NSView {

        let keysView = NSStackView(views: keys.map(makeCommand))
        keysView.setContentHuggingPriority(.required, for: .horizontal)

        return NSStackView(views: [makeLabel(text: text), keysView])
    }

    private lazy var globalContent: NSView = {

        return NSStackView(views: [
            makeGlobalShortcut(text: GlobalShortcuts.openCalendar, for: .showMainPopover),
            makeGlobalShortcut(text: GlobalShortcuts.openNextEvent, for: .showNextEventPopover),
            makeGlobalShortcut(text: GlobalShortcuts.openNextEventOptions, for: .showNextEventOptions),
            makeGlobalShortcut(text: GlobalShortcuts.openNextReminder, for: .showNextReminderPopover),
            makeGlobalShortcut(text: GlobalShortcuts.openNextReminderOptions, for: .showNextReminderOptions)
        ])
        .with(orientation: .vertical)
    }()

    private func makeGlobalShortcut(text: String, for shortcut: KeyboardShortcuts.Name) -> NSView {

        return NSStackView(views: [makeLabel(text: text), makeRecorder(for: shortcut)])
    }

    private func makeLabel(text: String) -> NSView {

        Label(text: text, font: .systemFont(ofSize: 13))
    }

    private func makeCommand(text: String) -> NSView {

        let charViews = text.split(separator: " ").map {
            Label(text: String($0), font: .systemFont(ofSize: 13, weight: .regular), align: .center)
        }

        // defer until after they are in the same hierarchy
        Task {
            for view in charViews {
                view.width(equalTo: commandCharWidth)
            }
        }

        return NSStackView(views: charViews).with(spacing: 0)
    }

    private func makeRecorder(for name: KeyboardShortcuts.Name) -> NSView {

        let shortcutRecorder = KeyboardShortcuts.RecorderCocoa(for: name)

        shortcutRecorder.setContentHuggingPriority(.required, for: .horizontal)

        return shortcutRecorder
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension Strings.Settings.Keyboard.LocalShortcuts {

    static let showWeekNumbers = Strings.Settings.Calendar.showWeekNumbers
    static let showDeclinedEvents = Strings.Settings.Calendar.showDeclinedEvents
    static let settings = Strings.Settings.title
    static let quit = Strings.quit
}

extension KeyboardShortcuts.Name {
    static let showMainPopover = Self("showMainPopover")
    static let showNextEventPopover = Self("showNextEventPopover")
    static let showNextEventOptions = Self("showNextEventOptions")
    static let showNextReminderPopover = Self("showNextReminderPopover")
    static let showNextReminderOptions = Self("showNextReminderOptions")
}
