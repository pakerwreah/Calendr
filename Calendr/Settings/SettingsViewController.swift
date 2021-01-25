//
//  SettingsViewController.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import RxCocoa
import RxSwift

class SettingsViewController: NSViewController {

    private let disposeBag = DisposeBag()

    private let settingsViewModel: SettingsViewModel
    private let calendarsViewModel: CalendarPickerViewModel

    private let showIconCheckbox = Checkbox(title: "Show icon")
    private let showDateCheckbox = Checkbox(title: "Show date")
    private let transparencySlider: NSSlider = {
        let slider = NSSlider(value: 0, minValue: 0, maxValue: 5, target: nil, action: nil)
        slider.allowsTickMarkValuesOnly = true
        slider.numberOfTickMarks = 6
        slider.controlSize = .small
        slider.refusesFirstResponder = true
        return slider
    }()

    init(settingsViewModel: SettingsViewModel, calendarsViewModel: CalendarPickerViewModel) {

        self.settingsViewModel = settingsViewModel
        self.calendarsViewModel = calendarsViewModel

        super.init(nibName: nil, bundle: nil)

        title = "Settings"

        setUpBindings()
    }

    override func loadView() {
        view = NSView()

        let stackView = NSStackView(.vertical)
        stackView.spacing = 24
        view.addSubview(stackView)
        stackView.edges(to: view, constant: 24)

        stackView.addArrangedSubview(
            makeSection(
                title: "Transparency",
                content: transparencySlider
            )
        )

        stackView.addArrangedSubview(
            makeSection(
                title: "Menu Bar",
                content: NSStackView(views: [showIconCheckbox, showDateCheckbox])
            )
        )

        let calendarsView = CalendarPickerView(viewModel: calendarsViewModel)

        stackView.addArrangedSubview(
            makeSection(
                title: "Calendars",
                content: calendarsView
            )
        )
    }

    private func makeSection(title: String, content: NSView) -> NSView {
        let stackView = NSStackView(.vertical)
        stackView.alignment = .left
        stackView.spacing = 6

        let label = Label(text: title, font: .systemFont(ofSize: 13, weight: .semibold))

        let divider: NSView = .spacer
        divider.height(equalTo: 1)
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor

        stackView.addArrangedSubviews(label, divider, content)

        stackView.setCustomSpacing(12, after: divider)

        return stackView
    }

    override func viewDidAppear() {

        view.window?.styleMask.remove(.resizable)

        NSApp.activate(ignoringOtherApps: true)
    }

    private func setUpBindings() {

        bind(
            checkbox: showIconCheckbox,
            observable: settingsViewModel.statusItemSettings.map(\.showIcon),
            observer: settingsViewModel.toggleStatusItemIcon
        )

        bind(
            checkbox: showDateCheckbox,
            observable: settingsViewModel.statusItemSettings.map(\.showDate),
            observer: settingsViewModel.toggleStatusItemDate
        )

        settingsViewModel.transparencyObservable
            .bind(to: transparencySlider.rx.integerValue)
            .disposed(by: disposeBag)

        transparencySlider.rx.value
            .skip(1)
            .map(Int.init)
            .bind(to: settingsViewModel.transparencyObserver)
            .disposed(by: disposeBag)
    }

    private func bind(checkbox: NSButton, observable: Observable<Bool>, observer: AnyObserver<Bool>) {
        observable
            .map { $0 ? .on : .off }
            .bind(to: checkbox.rx.state)
            .disposed(by: disposeBag)

        checkbox.rx.state
            .skip(1)
            .map { $0 == .on }
            .bind(to: observer)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
