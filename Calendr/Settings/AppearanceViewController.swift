//
//  AppearanceViewController.swift
//  Calendr
//
//  Created by Paker on 21/09/2024.
//

import Cocoa
import RxSwift

class AppearanceViewController: NSViewController, SettingsUI {

    private let disposeBag = DisposeBag()

    private let viewModel: SettingsViewModel

    // Transparency
    private let transparencySlider = Slider.make(minValue: 0, maxValue: 5, numberOfTickMarks: 6)

    // Accessibility
    private let textScalingSlider = Slider.make(minValue: 1, maxValue: 1.6, numberOfTickMarks: 13)

    init(viewModel: SettingsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()
        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.Appearance.view)
    }

    override func loadView() {

        view = NSView()

        let stackView = NSStackView(
            views: Sections.create([
                makeSection(title: Strings.Settings.Appearance.transparency, content: transparencyContent),
                makeSection(title: Strings.Settings.Appearance.accessibility, content: accessibilityContent)
            ])
            .disposed(by: disposeBag)
        )
        .with(spacing: Constants.contentSpacing)
        .with(orientation: .vertical)

        view.addSubview(stackView)

        stackView.edges(equalTo: view, margins: .init(bottom: 1))
    }

    private lazy var transparencyContent: NSView = {

        NSStackView(views: [
            NSImageView(image: Icons.Settings.transparencyLow),
            transparencySlider,
            NSImageView(image: Icons.Settings.transparencyHigh)
        ])
    }()

    private lazy var accessibilityContent: NSView = {

        NSStackView(views: [
            NSImageView(image: Icons.Settings.textSmall),
            textScalingSlider,
            NSImageView(image: Icons.Settings.textLarge)
        ])
    }()

    private func setUpBindings() {

        bind(
            control: transparencySlider,
            observable: viewModel.popoverTransparency,
            observer: viewModel.transparencyObserver
        )
        .disposed(by: disposeBag)

        bind(
            control: textScalingSlider,
            observable: viewModel.textScaling,
            observer: viewModel.textScalingObserver
        )
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
