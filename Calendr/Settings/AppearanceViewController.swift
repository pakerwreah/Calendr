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

    // Menu bar
    private let menuBarTextScalingSlider = Slider.make(minValue: 1.2, maxValue: 1.6, numberOfTickMarks: 13)

    // Calendar
    private let calendarScalingSlider = Slider.make(minValue: 1, maxValue: 1.6, numberOfTickMarks: 13)
    private let calendarTextScalingSlider = Slider.make(minValue: 1, maxValue: 1.6, numberOfTickMarks: 13)

    // Next Event
    private let nextEventTextScalingSlider = Slider.make(minValue: 1, maxValue: 1.6, numberOfTickMarks: 13)
    private let nextEventLengthSlider = Slider.make(minValue: 10, maxValue: 50, numberOfTickMarks: 13)
    private let nextEventDetectNotchCheckbox = Checkbox(title: Strings.Settings.NextEvent.detectNotch)

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

    func fittingSize(minWidth: CGFloat) -> NSSize {
        // FIXME: this is glitching like hell
        // .init(width: minWidth, height: view.fittingSize.height)
        view.fittingSize
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        let stackView = NSStackView(
            views: Sections.create([
                makeSection(title: Strings.Settings.Appearance.transparency, content: transparencyContent),
                makeSection(title: Strings.Settings.Appearance.accessibility, content: accessibilityContent),
                makeSection(title: Strings.Settings.Appearance.menuBar, content: menuBarContent),
                makeSection(title: Strings.Settings.Appearance.calendar, content: calendarContent),
                makeSection(title: Strings.Settings.Appearance.nextEvent, content: nextEventContent),
                makeThemeSection(),
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

    private func makeThemeSection() -> DisposableWrapper<NSView> {

        let btnStack = NSStackView(.horizontal)
        btnStack.addArrangedSubview(.spacer)

        for mode in AppearanceMode.allCases {
            let button = CursorButton(cursor: .pointingHand)
            button.image = mode.icon
            button.refusesFirstResponder = true
            button.bezelStyle = .circular
            button.setButtonType(.pushOnPushOff)
            btnStack.addArrangedSubview(button)

            button.rx.tap.map(mode)
                .bind(to: viewModel.appearanceModeObserver)
                .disposed(by: disposeBag)

            viewModel.appearanceMode
                .map { $0 == mode ? .on : .off }
                .bind(to: button.rx.state)
                .disposed(by: disposeBag)
        }

        let (divider, disposable) = makeDivider().unwrap()

        let container = NSStackView(views: [divider, btnStack])
            .with(orientation: .vertical)
            .with(spacing: Constants.contentSpacing / 2)

        return .init(value: container, disposable: disposable)
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

    private lazy var menuBarContent: NSView = {

        NSStackView(views: [
            makeIcon(Icons.Settings.textSmall, .large),
            menuBarTextScalingSlider,
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
            makeIcon(Icons.Settings.length_small, .large),
            nextEventLengthSlider,
            makeIcon(Icons.Settings.length_big, .large),
        ])

        nextEventDetectNotchCheckbox.font = .systemFont(ofSize: 11, weight: .light)

        // Next event text scaling

        let textScalingView = NSStackView(views: [
            makeIcon(Icons.Settings.textSmall, .large),
            nextEventTextScalingSlider,
            makeIcon(Icons.Settings.textLarge, .large)
        ])

        // Next event stack view

        return NSStackView(views: [
            textScalingView,
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
            control: menuBarTextScalingSlider,
            observable: viewModel.statusItemTextScaling,
            observer: viewModel.statusItemTextScalingObserver
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
            control: nextEventTextScalingSlider,
            observable: viewModel.eventStatusItemTextScaling,
            observer: viewModel.eventStatusItemTextScalingObserver
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

    static let menuBar = Strings.Settings.menuBar
    static let calendar = Strings.Settings.calendar
    static let nextEvent = Strings.Settings.nextEvent
}

private extension AppearanceMode {

    var icon: NSImage {
        switch self {
        case .automatic:
            return Icons.Appearance.automatic
        case .light:
            return Icons.Appearance.light
        case .dark:
            return Icons.Appearance.dark
        }
    }
}
