//
//  LocalShortcutsViewController.swift
//  Calendr
//
//  Created by Paker on 13/08/2026.
//

import AppKit
import RxSwift

private typealias LocalShortcuts = Strings.Settings.Keyboard.LocalShortcuts

class LocalShortcutsViewController: NSViewController, SettingsUI {

    private let disposeBag = DisposeBag()

    private var commandCharWidth = NSLayoutGuide()

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        title = LocalShortcuts.title
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setUpContent()
        setUpBindings()
    }

    private lazy var contentView = NSStackView(
        views: [
            makeShortcut(text: LocalShortcuts.prevDate, keys: "←"),
            makeShortcut(text: LocalShortcuts.nextDate, keys: "→"),
            makeShortcut(text: LocalShortcuts.prevWeek, keys: "↑"),
            makeShortcut(text: LocalShortcuts.nextWeek, keys: "↓"),
            makeShortcut(text: LocalShortcuts.prevMonth, keys: "⌘ ←", "⌘ ↑"),
            makeShortcut(text: LocalShortcuts.nextMonth, keys: "⌘ →", "⌘ ↓"),
            makeShortcut(text: LocalShortcuts.currDate, keys: "⌫"),
            makeShortcut(text: LocalShortcuts.openDate, keys: "↵"),
            makeShortcut(text: LocalShortcuts.showWeekNumbers, keys: "⌥ W"),
            makeShortcut(text: LocalShortcuts.showDeclinedEvents, keys: "⌥ D"),
            makeShortcut(text: LocalShortcuts.pinCalendar, keys: "⌘ P"),
            makeShortcut(text: LocalShortcuts.settings, keys: "⌘ ,"),
            makeShortcut(text: LocalShortcuts.quit, keys: "⌘ Q"),
        ])
        .with(orientation: .vertical)
        .with(alignment: .width)
        .with(insets: .init(top: Constants.contentSpacing))

    private func setUpContent() {

        view.addLayoutGuide(commandCharWidth)

        contentView.setHuggingPriority(.required, for: .vertical)

        view.addSubview(contentView)

        contentView.edges(equalTo: view)
    }

    private func setUpBindings() {

        Scaling.observable
            .map { CGFloat(16 * $0) }
            .bind(to: commandCharWidth.width(equalTo: 1).rx.constant)
            .disposed(by: disposeBag)
    }

    private func makeShortcut(text: String, keys: String...) -> NSView {
        
        let label = Label(text: text, font: .systemFont(ofSize: 13))

        let keysView = NSStackView(views: keys.map(makeCommand))

        keysView.setContentHuggingPriority(.required, for: .horizontal)

        return NSStackView(views: [label, keysView])
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
}

private extension LocalShortcuts {
    static let showWeekNumbers = Strings.Settings.Calendar.showWeekNumbers
    static let showDeclinedEvents = Strings.Settings.Calendar.showDeclinedEvents
    static let settings = Strings.Settings.title
    static let quit = Strings.quit
}
