//
//  GeneralSettingsViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import Cocoa
import RxSwift

class GeneralSettingsViewController: NSViewController {

    private let disposeBag = DisposeBag()

    private let viewModel: SettingsViewModel

    private let showMenuBarIconCheckbox = Checkbox(title: Strings.Settings.MenuBar.showIcon)
    private let showMenuBarDateCheckbox = Checkbox(title: Strings.Settings.MenuBar.showDate)
    private let showNextEventCheckbox = Checkbox(title: Strings.Settings.MenuBar.showNextEvent)
    private let showWeekNumbersCheckbox = Checkbox(title: Strings.Settings.Calendar.showWeekNumbers)
    private let fadePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.fade)
    private let hidePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.hide)
    private let dateFormatDropdown = Dropdown()

    init(viewModel: SettingsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.General.view)
    }

    override func loadView() {

        view = NSView()

        let stackView = NSStackView(views: [
            makeSection(title: Strings.Settings.menuBar, content: menuBarContent),
            makeSection(title: Strings.Settings.calendar, content: showWeekNumbersCheckbox),
            makeSection(title: Strings.Settings.events, content: eventsContent),
            makeSection(title: Strings.Settings.transparency, content: transparencySlider)
        ])
        .with(spacing: Constants.contentSpacing)
        .with(orientation: .vertical)

        view.addSubview(stackView)

        stackView.edges(to: view)
    }

    private lazy var menuBarContent: NSView = {

        let checkboxes = NSStackView(views: [
            NSStackView(views: [
                showMenuBarIconCheckbox, showMenuBarDateCheckbox
            ]),
            showNextEventCheckbox
        ])
        .with(orientation: .vertical)

        let dateFormat = NSStackView(views: [
            Label(text: "\(Strings.Settings.MenuBar.dateFormat):"),
            dateFormatDropdown,
            Label(
                text: " \(Strings.Settings.MenuBar.DateFormat.info)",
                font: .systemFont(ofSize: 10, weight: .light)
            )
        ])
        .with(orientation: .vertical)

        return NSStackView(views: [checkboxes, dateFormat])
            .with(spacing: Constants.contentSpacing)
            .with(orientation: .vertical)
    }()

    private lazy var eventsContent: NSView = {
        NSStackView(views: [
            Label(text: "\(Strings.Settings.Events.finished):"), fadePastEventsRadio, hidePastEventsRadio
        ])
    }()

    private let transparencySlider: NSSlider = {
        let slider = NSSlider(value: 0, minValue: 0, maxValue: 5, target: nil, action: nil)
        slider.allowsTickMarkValuesOnly = true
        slider.numberOfTickMarks = 6
        slider.controlSize = .small
        slider.refusesFirstResponder = true
        return slider
    }()

    private func makeSection(title: String, content: NSView) -> NSView {

        let label = Label(text: title, font: .systemFont(ofSize: 13, weight: .semibold))

        let divider: NSView = .spacer(height: 1)
        divider.wantsLayer = true

        divider.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.cgColor }
            .bind(to: divider.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        let stackView = NSStackView(views: [
            label,
            divider,
            NSStackView(views: [.dummy, content, .dummy])
        ])
        .with(orientation: .vertical)
        .with(alignment: .left)
        .with(spacing: 6)
        .with(spacing: 12, after: divider)

        return stackView
    }

    private func setUpBindings() {

        bind(
            control: showMenuBarIconCheckbox,
            observable: viewModel.showStatusItemIcon,
            observer: viewModel.toggleStatusItemIcon
        )

        bind(
            control: showMenuBarDateCheckbox,
            observable: viewModel.showStatusItemDate,
            observer: viewModel.toggleStatusItemDate
        )

        bind(
            control: showNextEventCheckbox,
            observable: viewModel.showEventStatusItem,
            observer: viewModel.toggleEventStatusItem
        )

        bind(
            control: showWeekNumbersCheckbox,
            observable: viewModel.showWeekNumbers,
            observer: viewModel.toggleWeekNumbers
        )

        bind(
            control: fadePastEventsRadio,
            observable: viewModel.showPastEvents,
            observer: viewModel.togglePastEvents
        )

        bind(
            control: hidePastEventsRadio,
            observable: viewModel.showPastEvents.map(!),
            observer: viewModel.togglePastEvents.mapObserver(!)
        )

        viewModel.popoverTransparency
            .bind(to: transparencySlider.rx.integerValue)
            .disposed(by: disposeBag)

        transparencySlider.rx.value
            .skip(1)
            .map(Int.init)
            .bind(to: viewModel.transparencyObserver)
            .disposed(by: disposeBag)

        let dateFormatStyle = dateFormatDropdown.rx.controlProperty(
            getter: { (dropdown: NSPopUpButton) -> DateStyle in
                DateStyle(rawValue: UInt(dropdown.indexOfSelectedItem + 1)) ?? .none
            },
            setter: { (dropdown: NSPopUpButton, style: DateStyle) in
                dropdown.selectItem(at: Int(style.rawValue) - 1)
            }
        )

        dateFormatStyle
            .skip(1)
            .bind(to: viewModel.statusItemDateStyleObserver)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.dateFormatOptions, viewModel.statusItemDateStyle
        )
        .bind { [dateFormatDropdown] options, dateStyle in
            dateFormatDropdown.removeAllItems()
            dateFormatDropdown.addItems(withTitles: options)
            dateFormatStyle.onNext(dateStyle)
        }
        .disposed(by: disposeBag)
    }

    private func bind(control: NSButton, observable: Observable<Bool>, observer: AnyObserver<Bool>) {
        observable
            .map { $0 ? .on : .off }
            .bind(to: control.rx.state)
            .disposed(by: disposeBag)

        control.rx.state
            .skip(1)
            .map { $0 == .on }
            .bind(to: observer)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Constants {

    static let contentSpacing: CGFloat = 16
}
