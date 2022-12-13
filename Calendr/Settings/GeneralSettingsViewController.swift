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
    private let nextEventDetectNotchCheckbox = Checkbox(title: Strings.Settings.MenuBar.nextEventDetectNotch)
    private let showWeekNumbersCheckbox = Checkbox(title: Strings.Settings.Calendar.showWeekNumbers)
    private let showDeclinedEventsCheckbox = Checkbox(title: Strings.Settings.Calendar.showDeclinedEvents)
    private let preserveSelectedDateCheckbox = Checkbox(title: Strings.Settings.Calendar.preserveSelectedDate)
    private let fadePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.fade)
    private let hidePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.hide)
    private let dateFormatDropdown = Dropdown()
    private let dateFormatTextField = NSTextField()
    private let nextEventRangeStepper = NSStepper()

    private let nextEventLengthSlider = NSSlider.make(minValue: 10, maxValue: 30)
    private let transparencySlider = NSSlider.make(minValue: 0, maxValue: 5)
    private let calendarScalingSlider = NSSlider.make(minValue: 1, maxValue: 1.2, numberOfTickMarks: 5)

    init(viewModel: SettingsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        dateFormatTextField.refusesFirstResponder = true

        setUpAccessibility()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.General.view)

        dateFormatDropdown.setAccessibilityIdentifier(Accessibility.Settings.General.dateFormatDropdown)
        dateFormatTextField.setAccessibilityIdentifier(Accessibility.Settings.General.dateFormatInput)
    }

    override func loadView() {

        view = NSView()

        let stackView = NSStackView(views: [
            makeSection(title: Strings.Settings.menuBar, content: menuBarContent),
            makeSection(title: Strings.Settings.nextEvent, content: nextEventContent),
            makeSection(title: Strings.Settings.calendar, content: calendarContent),
            makeSection(title: Strings.Settings.events, content: eventsContent),
            makeSection(title: Strings.Settings.transparency, content: transparencySlider),
        ])
        .with(spacing: Constants.contentSpacing)
        .with(orientation: .vertical)

        view.addSubview(stackView)

        stackView.edges(to: view, insets: .init(bottom: 1))
    }

    private lazy var menuBarContent: NSView = {

        let checkboxes = NSStackView(views: [showMenuBarIconCheckbox, showMenuBarDateCheckbox])

        dateFormatTextField.placeholderString = viewModel.dateFormatPlaceholder

        let dateFormat = NSStackView(views: [
            Label(text: "\(Strings.Settings.MenuBar.dateFormat):"),
            dateFormatDropdown,
            dateFormatTextField
        ])
        .with(orientation: .vertical)

        return NSStackView(views: [checkboxes, dateFormat])
            .with(spacing: Constants.contentSpacing)
            .with(orientation: .vertical)
    }()

    private lazy var nextEventContent: NSView = {

        let nextEventLengthView = NSStackView(views: [
            NSImageView(image: Icons.Settings.ruler.with(scale: .large)),
            nextEventLengthSlider
        ])

        nextEventDetectNotchCheckbox.font = .systemFont(ofSize: 11, weight: .light)

        nextEventRangeStepper.minValue = 1
        nextEventRangeStepper.maxValue = 24
        nextEventRangeStepper.valueWraps = false
        nextEventRangeStepper.refusesFirstResponder = true

        let stepperLabel = Label(font: showNextEventCheckbox.font)

        let stepperProperty = nextEventRangeStepper.rx.controlProperty(
            getter: \.integerValue,
            setter: { $0.integerValue = $1}
        )

        viewModel.eventStatusItemCheckRange
            .bind(to: stepperProperty)
            .disposed(by: disposeBag)

        stepperProperty
            .bind(to: viewModel.eventStatusItemCheckRangeObserver)
            .disposed(by: disposeBag)

        viewModel.eventStatusItemCheckRangeLabel
            .bind(to: stepperLabel.rx.text)
            .disposed(by: disposeBag)

        return NSStackView(views: [
            NSStackView(views: [showNextEventCheckbox, stepperLabel, nextEventRangeStepper]),
            nextEventLengthView,
            nextEventDetectNotchCheckbox
        ])
        .with(orientation: .vertical)
    }()

    private lazy var showDeclinedEventsTooltip: NSView = {

        let tooltipViewController = NSViewController()
        let view = NSView()
        tooltipViewController.view = view
        let label = Label(text: Strings.Settings.Calendar.showDeclinedEventsTooltip)
        label.preferredMaxLayoutWidth = 190
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        view.addSubview(label)
        label.edges(to: view, constant: 8)

        let button = ImageButton(image: Icons.Settings.tooltip, cursor: nil)

        let popover = NSPopover()
        popover.contentViewController = tooltipViewController
        popover.behavior = .transient
        popover.animates = false

        button.rx.isHovered
            .bind { isHovered in
                guard isHovered else { return popover.performClose(nil) }
                popover.show(relativeTo: .zero, of: button, preferredEdge: .maxX)
            }
            .disposed(by: disposeBag)
        
        return button
    }()

    private lazy var calendarContent: NSView = {
        NSStackView(views: [
            NSStackView(views: [
                NSImageView(image: Icons.Settings.zoomOut),
                calendarScalingSlider,
                NSImageView(image: Icons.Settings.zoomIn)
            ]),
            .dummy,
            showWeekNumbersCheckbox,
            NSStackView(views: [showDeclinedEventsCheckbox, showDeclinedEventsTooltip]),
            preserveSelectedDateCheckbox
        ])
        .with(orientation: .vertical)
    }()

    private lazy var eventsContent: NSView = {
        NSStackView(views: [
            Label(text: "\(Strings.Settings.Events.finished):"), fadePastEventsRadio, hidePastEventsRadio
        ])
    }()

    private func makeSection(title: String, content: NSView) -> NSView {

        let label = Label(text: title, font: .systemFont(ofSize: 13, weight: .semibold))

        let divider: NSView = .spacer(height: 1)
        divider.wantsLayer = true

        divider.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.effectiveCGColor }
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

        viewModel.eventStatusItemLength
            .bind(to: nextEventLengthSlider.rx.integerValue)
            .disposed(by: disposeBag)

        bind(
            control: nextEventDetectNotchCheckbox,
            observable: viewModel.eventStatusItemDetectNotch,
            observer: viewModel.toggleEventStatusItemDetectNotch
        )

        nextEventLengthSlider.rx.value
            .skip(1)
            .map(Int.init)
            .bind(to: viewModel.eventStatusItemLengthObserver)
            .disposed(by: disposeBag)

        bind(
            control: showWeekNumbersCheckbox,
            observable: viewModel.showWeekNumbers,
            observer: viewModel.toggleWeekNumbers
        )

        bind(
            control: showDeclinedEventsCheckbox,
            observable: viewModel.showDeclinedEvents,
            observer: viewModel.toggleDeclinedEvents
        )

        bind(
            control: preserveSelectedDateCheckbox,
            observable: viewModel.preserveSelectedDate,
            observer: viewModel.togglePreserveSelectedDate
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

        viewModel.calendarScaling
            .bind(to: calendarScalingSlider.rx.doubleValue)
            .disposed(by: disposeBag)

        calendarScalingSlider.rx.value
            .skip(1)
            .bind(to: viewModel.calendarScalingObserver)
            .disposed(by: disposeBag)

        let dateFormatStyle = dateFormatDropdown.rx.controlProperty(
            getter: { (dropdown: NSPopUpButton) -> DateStyle in
                DateStyle(rawValue: UInt(dropdown.indexOfSelectedItem + 1)) ?? .none
            },
            setter: { (dropdown: NSPopUpButton, style: DateStyle) in
                dropdown.selectItem(at: (style.isCustom ? dropdown.numberOfItems : Int(style.rawValue)) - 1)
            }
        )

        dateFormatStyle
            .skip(1)
            .bind(to: viewModel.statusItemDateStyleObserver)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.dateStyleOptions, viewModel.statusItemDateStyle
        )
        .bind { [dateFormatDropdown] options, dateStyle in
            dateFormatDropdown.removeAllItems()
            dateFormatDropdown.addItems(withTitles: options)
            dateFormatStyle.onNext(dateStyle)
        }
        .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .map(!)
            .bind(to: dateFormatTextField.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .map(true)
            .bind(to: view.rx.needsLayout)
            .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .skip(1)
            .matching(true)
            .bind(to: dateFormatTextField.rx.hasFocus)
            .disposed(by: disposeBag)

        dateFormatTextField.rx.text
            .skip(1)
            .skipNil()
            .bind(to: viewModel.statusItemDateFormatObserver)
            .disposed(by: disposeBag)

        viewModel.statusItemDateFormat
            .bind(to: dateFormatTextField.rx.text)
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

private extension NSSlider {

    static func make(minValue: Double, maxValue: Double, numberOfTickMarks: Int = 6) -> NSSlider {
        let slider = NSSlider(value: 0, minValue: minValue, maxValue: maxValue, target: nil, action: nil)
        slider.allowsTickMarkValuesOnly = true
        slider.numberOfTickMarks = numberOfTickMarks
        slider.controlSize = .small
        slider.refusesFirstResponder = true
        return slider
    }
}

private enum Constants {

    static let contentSpacing: CGFloat = 16
}
