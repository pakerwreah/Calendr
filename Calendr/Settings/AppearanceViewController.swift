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
    
    // Calendar
    private let calendarScalingSlider = Slider.make(minValue: 1, maxValue: 1.6, numberOfTickMarks: 13)
    private let calendarTextScalingSlider = Slider.make(minValue: 1, maxValue: 1.6, numberOfTickMarks: 13)

    // Next Event
    private let nextEventRangeStepper = NSStepper()
    private let nextEventLengthSlider = Slider.make(minValue: 10, maxValue: 50, numberOfTickMarks: 12)
    private let nextEventDetectNotchCheckbox = Checkbox(title: Strings.Settings.NextEvent.detectNotch)
    private let nextEventFontSizeStepper = NSStepper()

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
                makeSection(title: Strings.Settings.Appearance.accessibility, content: accessibilityContent),
                makeSection(title: Strings.Settings.Appearance.calendar, content: calendarContent),
                makeSection(title: Strings.Settings.Appearance.nextEvent, content: nextEventContent),
            ])
            .disposed(by: disposeBag)
        )
        .with(spacing: Constants.contentSpacing)
        .with(orientation: .vertical)

        stackView.setHuggingPriority(.defaultHigh, for: .horizontal)
        stackView.setHuggingPriority(.required, for: .vertical)

        view.addSubview(stackView)

        stackView.edges(equalTo: view)
    }

    private lazy var transparencyContent: NSView = {

        NSStackView(views: [
            makeIcon(Icons.Settings.transparencyLow),
            transparencySlider,
            makeIcon(Icons.Settings.transparencyHigh)
        ])
    }()

    private lazy var accessibilityContent: NSView = {

        NSStackView(views: [
            makeIcon(Icons.Settings.textSmall, .large),
            textScalingSlider,
            makeIcon(Icons.Settings.textLarge, .large)
        ])
    }()
    
    private lazy var calendarContent: NSView = {

        NSStackView(views: [
            NSStackView(views: [
                makeIcon(Icons.Settings.zoomOut),
                calendarScalingSlider,
                makeIcon(Icons.Settings.zoomIn)
            ]),
            .dummy,
            NSStackView(views: [
                makeIcon(Icons.Settings.textSmall, .large),
                calendarTextScalingSlider,
                makeIcon(Icons.Settings.textLarge, .large)
            ])
        ])
        .with(orientation: .vertical)
    }()

    private lazy var nextEventContent: NSView = {

        // Next event length

        let nextEventLengthView = NSStackView(views: [
            makeIcon(Icons.Settings.ruler, .large),
            nextEventLengthSlider
        ])

        nextEventDetectNotchCheckbox.font = .systemFont(ofSize: 11, weight: .light)

        // Next event font size

        let fontSizeLabel = Label(text: Strings.Settings.NextEvent.fontSize, font: .systemFont(ofSize: 13))
        let fontSizeStepperLabel = Label(font: .systemFont(ofSize: 13))

        nextEventFontSizeStepper.minValue = 10
        nextEventFontSizeStepper.maxValue = 13
        nextEventFontSizeStepper.increment = 0.5
        nextEventFontSizeStepper.valueWraps = false
        nextEventFontSizeStepper.refusesFirstResponder = true
        nextEventFontSizeStepper.focusRingType = .none

        let fontSizeStepperProperty = nextEventFontSizeStepper.rx.controlProperty(
            getter: \.floatValue,
            setter: { $0.floatValue = $1 }
        )

        viewModel.eventStatusItemFontSize
            .bind(to: fontSizeStepperProperty)
            .disposed(by: disposeBag)

        fontSizeStepperProperty
            .bind(to: viewModel.eventStatusItemFontSizeObserver)
            .disposed(by: disposeBag)

        viewModel.eventStatusItemFontSize
            .map { .init(format: "%.1f", $0) }
            .bind(to: fontSizeStepperLabel.rx.text)
            .disposed(by: disposeBag)

        // Next event stack view

        return NSStackView(views: [
            NSStackView(views: [fontSizeLabel, .spacer, fontSizeStepperLabel, nextEventFontSizeStepper]),
            nextEventLengthView,
            nextEventDetectNotchCheckbox,
        ])
        .with(orientation: .vertical)
    }()

    private func setUpBindings() {

        bind(
            control: transparencySlider,
            observable: viewModel.popoverTransparency,
            observer: viewModel.transparencyObserver
        )
        .disposed(by: disposeBag)

        bind(
            control: calendarScalingSlider,
            observable: viewModel.calendarScaling,
            observer: viewModel.calendarScalingObserver
        )
        .disposed(by: disposeBag)

        bind(
            control: textScalingSlider,
            observable: viewModel.textScaling,
            observer: viewModel.textScalingObserver
        )
        .disposed(by: disposeBag)
        
        bind(
            control: calendarTextScalingSlider,
            observable: viewModel.calendarTextScaling,
            observer: viewModel.calendarTextScalingObserver
        )
        .disposed(by: disposeBag)

        bind(
            control: nextEventLengthSlider,
            observable: viewModel.eventStatusItemLength,
            observer: viewModel.eventStatusItemLengthObserver
        )
        .disposed(by: disposeBag)

        bind(
            control: nextEventDetectNotchCheckbox,
            observable: viewModel.eventStatusItemDetectNotch,
            observer: viewModel.toggleEventStatusItemDetectNotch
        )
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func makeIcon(_ image: NSImage, _ scale: NSImage.SymbolScale = .medium) -> NSImageView {
    .init(image: image.with(scale: scale)).with(color: .labelColor).with(width: 20)
}

private extension Strings.Settings.Appearance {

    static let calendar = Strings.Settings.calendar
    static let nextEvent = Strings.Settings.nextEvent
}
