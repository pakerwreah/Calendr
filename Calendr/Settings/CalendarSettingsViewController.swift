//
//  CalendarSettingsViewController.swift
//  Calendr
//
//  Created by Paker on 01/08/2026.
//

import Cocoa
import RxSwift

class CalendarSettingsViewController: NSViewController, SettingsUI {

    private let disposeBag = DisposeBag()
    private let holidayCalendarCheckbox = Checkbox(title: Strings.Settings.Calendar.holidayCalendar)
    private let showNextEventCheckbox = Checkbox(title: Strings.Settings.NextEvent.showNextEvent)
    private let showNextEventTitleCheckbox = Checkbox(title: Strings.Settings.NextEvent.showNextEventTitle)
    private let preferredBrowserLabel = Label(text: Strings.Settings.Calendar.preferredBrowser)

    private let viewModel: CalendarSettingsViewModel

    init(viewModel: CalendarSettingsViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        let nextEventContent = NSStackView(views: [
            showNextEventCheckbox,
            showNextEventTitleCheckbox
        ])
        .with(orientation: .vertical)

        let browserContent = NSStackView(views: [
            preferredBrowserLabel,
            BrowserPicker(viewModel: viewModel.browserPickerViewModel)
        ])

        let content = NSStackView(views: [holidayCalendarCheckbox, nextEventContent, browserContent])
            .with(orientation: .vertical)
            .with(spacing: Constants.sectionSpacing)

        view.addSubview(content)

        content.edges(equalTo: view, margins: .init(top: 48, left: 24, bottom: 24, right: 24))

        let closeButton = NSButton(image: Icons.CalendarSettings.close, target: self, action: #selector(cancelOperation))
        closeButton.isBordered = false

        view.addSubview(closeButton)

        closeButton.top(equalTo: view, constant: 16)
        closeButton.trailing(equalTo: view, constant: -16)

        let titleLabel = Label(text: viewModel.title)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.alignment = .center

        view.addSubview(titleLabel)

        titleLabel.center(in: closeButton, orientation: .vertical)
        titleLabel.leading(equalTo: view, constant: 50)
        titleLabel.trailing(equalTo: view, constant: -50)

        view.width(greaterThanOrEqualTo: 300)

        setUpBindings()
    }

    override func viewDidAppear() {

        super.viewDidAppear()

        guard let window = view.window else { return }

        window.setContentSize(view.fittingSize)

        window.styleMask.remove(.resizable)
        window.makeFirstResponder(view)

        NSApp.activate(ignoringOtherApps: true)
    }

    override func cancelOperation(_ sender: Any?) {
        dismiss(nil)
    }

    private func setUpBindings() {
        bind(
            control: holidayCalendarCheckbox,
            observable: viewModel.isHolidayCalendar,
            observer: viewModel.isHolidayCalendarObserver
        )
        .disposed(by: disposeBag)

        bind(
            control: showNextEventCheckbox,
            observable: viewModel.showNextEvent,
            observer: viewModel.showNextEventObserver
        )
        .disposed(by: disposeBag)

        bind(
            control: showNextEventTitleCheckbox,
            observable: viewModel.showNextEventTitle,
            observer: viewModel.showNextEventTitleObserver
        )
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
