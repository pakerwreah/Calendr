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
                content: NSStackView(views: [showIconCheckbox, showDateCheckbox])
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

        let divider: NSView = .spacer
        divider.height(equalTo: 1)
        divider.wantsLayer = true
        divider.layer?.backgroundColor = NSColor.separatorColor.cgColor

        stackView.addArrangedSubviews(label, divider, content)

        stackView.setCustomSpacing(12, after: divider)

        return stackView
    }

    private func setUpBindings() {

        bind(
            checkbox: showIconCheckbox,
            observable: viewModel.statusItemSettings.map(\.showIcon),
            observer: viewModel.toggleStatusItemIcon
        )

        bind(
            checkbox: showDateCheckbox,
            observable: viewModel.statusItemSettings.map(\.showDate),
            observer: viewModel.toggleStatusItemDate
        )

        viewModel.transparencyObservable
            .bind(to: transparencySlider.rx.integerValue)
            .disposed(by: disposeBag)

        transparencySlider.rx.value
            .skip(1)
            .map(Int.init)
            .bind(to: viewModel.transparencyObserver)
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
