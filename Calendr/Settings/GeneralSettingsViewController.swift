//
//  GeneralSettingsViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import RxCocoa
import RxSwift

class GeneralSettingsViewController: NSViewController {

    private let disposeBag = DisposeBag()

    private let viewModel: SettingsViewModel

    private let showMenuBarIconCheckbox = Checkbox(title: "Show icon")
    private let showMenuBarDateCheckbox = Checkbox(title: "Show date")
    private let fadePastEventsRadio = Radio(title: "Fade")
    private let hidePastEventsRadio = Radio(title: "Hide")

    private let transparencySlider: NSSlider = {
        let slider = NSSlider(value: 0, minValue: 0, maxValue: 5, target: nil, action: nil)
        slider.allowsTickMarkValuesOnly = true
        slider.numberOfTickMarks = 6
        slider.controlSize = .small
        slider.refusesFirstResponder = true
        return slider
    }()

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpBindings()
    }

    override func loadView() {
        view = NSView()

        let stackView = NSStackView(.vertical)
        stackView.spacing = 24
        view.addSubview(stackView)
        stackView.edges(to: view)

        stackView.addArrangedSubviews(
            makeSection(
                title: "Menu Bar",
                content: NSStackView(views: [showMenuBarIconCheckbox, showMenuBarDateCheckbox])
            ),
            makeSection(
                title: "Events",
                content: NSStackView(views: [Label(text: "Finished:"), fadePastEventsRadio, hidePastEventsRadio])
            ),
            makeSection(
                title: "Transparency",
                content: transparencySlider
            )
        )
    }

    private func makeSection(title: String, content: NSView) -> NSView {

        let stackView = NSStackView(.vertical)
        stackView.alignment = .left
        stackView.spacing = 6

        let label = Label(text: title, font: .systemFont(ofSize: 13, weight: .semibold))

        let divider: NSView = .spacer(height: 1)
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor

        stackView.addArrangedSubviews(label, divider, NSStackView(views: [.spacer(width: 0), content, .spacer(width: 0)]))

        stackView.setCustomSpacing(12, after: divider)

        return stackView
    }

    private func setUpBindings() {

        bind(
            control: showMenuBarIconCheckbox,
            observable: viewModel.statusItemSettings.map(\.showIcon),
            observer: viewModel.toggleStatusItemIcon
        )

        bind(
            control: showMenuBarDateCheckbox,
            observable: viewModel.statusItemSettings.map(\.showDate),
            observer: viewModel.toggleStatusItemDate
        )

        bind(
            control: fadePastEventsRadio,
            observable: viewModel.showPastEvents,
            observer: viewModel.toggleShowPastEvents
        )

        bind(
            control: hidePastEventsRadio,
            observable: viewModel.showPastEvents.map(\.isFalse),
            observer: viewModel.toggleShowPastEvents.mapObserver(\.isFalse)
        )

        viewModel.popoverTransparency
            .bind(to: transparencySlider.rx.integerValue)
            .disposed(by: disposeBag)

        transparencySlider.rx.value
            .skip(1)
            .map(Int.init)
            .bind(to: viewModel.transparencyObserver)
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
