//
//  GeneralSettingsViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import Cocoa
import RxSwift

class GeneralSettingsViewController: NSViewController, SettingsUI {

    let disposeBag = DisposeBag()

    private let viewModel: SettingsViewModel

    // Menu Bar
    private let autoLaunchCheckbox = Checkbox(title: Strings.Settings.MenuBar.autoLaunch)
    private let showMenuBarIconCheckbox = Checkbox(title: Strings.Settings.MenuBar.showIcon)
    private let showMenuBarDateCheckbox = Checkbox(title: Strings.Settings.MenuBar.showDate)
    private let showMenuBarBackgroundCheckbox = Checkbox(title: Strings.Settings.MenuBar.showBackground)
    private let iconStyleDropdown = Dropdown()
    private let dateFormatDropdown = Dropdown()
    private let dateFormatTextField = NSTextField()

    // Next Event
    private let showNextEventCheckbox = Checkbox(title: Strings.Settings.MenuBar.showNextEvent)
    private let nextEventRangeStepper = NSStepper()
    private let nextEventLengthSlider = NSSlider.make(minValue: 10, maxValue: 50, numberOfTickMarks: 12)
    private let nextEventDetectNotchCheckbox = Checkbox(title: Strings.Settings.MenuBar.nextEventDetectNotch)
    private let nextEventFontSizeStepper = NSStepper()

    // Calendar
    private let calendarScalingSlider = NSSlider.make(minValue: 1, maxValue: 1.2, numberOfTickMarks: 5)
    private let firstWeekdayPrev = ImageButton(image: Icons.Settings.prev)
    private let firstWeekdayNext = ImageButton(image: Icons.Settings.next)
    private let highlightedWeekdaysButtons = NSStackView()
    private let showWeekNumbersCheckbox = Checkbox(title: Strings.Settings.Calendar.showWeekNumbers)
    private let showDeclinedEventsCheckbox = Checkbox(title: Strings.Settings.Calendar.showDeclinedEvents)
    private let preserveSelectedDateCheckbox = Checkbox(title: Strings.Settings.Calendar.preserveSelectedDate)

    // Events
    private let fadePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.fade)
    private let hidePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.hide)

    // Transparency
    private let transparencySlider = NSSlider.make(minValue: 0, maxValue: 5, numberOfTickMarks: 6)

    init(viewModel: SettingsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.General.view)

        iconStyleDropdown.setAccessibilityIdentifier(Accessibility.Settings.General.iconStyleDropdown)
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

        iconStyleDropdown.height(equalTo: showMenuBarIconCheckbox)

        if #unavailable(macOS 13.0) {
            autoLaunchCheckbox.isHidden = true
        }
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        setUpAccessibility()

        setUpBindings()
    }

    private lazy var menuBarContent: NSView = {

        dateFormatTextField.placeholderString = viewModel.dateFormatPlaceholder
        dateFormatTextField.refusesFirstResponder = true
        dateFormatTextField.focusRingType = .none

        iconStyleDropdown.isBordered = false
        iconStyleDropdown.setContentHuggingPriority(.required, for: .horizontal)

        let iconStyle = NSStackView(views: [
            showMenuBarIconCheckbox,
            iconStyleDropdown
        ])
        .with(insets: .init(right: 4))

        let dateFormat = NSStackView(views: [
            showMenuBarDateCheckbox,
            dateFormatDropdown,
            dateFormatTextField
        ])
        .with(orientation: .vertical)

        return NSStackView(views: [
            autoLaunchCheckbox,
            iconStyle,
            dateFormat,
            showMenuBarBackgroundCheckbox
        ])
        .with(orientation: .vertical)
    }()

    private lazy var nextEventContent: NSView = {

        // Next event length

        let nextEventLengthView = NSStackView(views: [
            NSImageView(image: Icons.Settings.ruler.with(scale: .large)),
            nextEventLengthSlider
        ])

        nextEventDetectNotchCheckbox.font = .systemFont(ofSize: 11, weight: .light)

        // Next event range

        nextEventRangeStepper.minValue = 1
        nextEventRangeStepper.maxValue = 24
        nextEventRangeStepper.valueWraps = false
        nextEventRangeStepper.refusesFirstResponder = true
        nextEventRangeStepper.focusRingType = .none

        let rangeStepperLabel = Label(font: .systemFont(ofSize: 13))

        let rangeStepperProperty = nextEventRangeStepper.rx.controlProperty(
            getter: \.integerValue,
            setter: { $0.integerValue = $1 }
        )

        viewModel.eventStatusItemCheckRange
            .bind(to: rangeStepperProperty)
            .disposed(by: disposeBag)

        rangeStepperProperty
            .bind(to: viewModel.eventStatusItemCheckRangeObserver)
            .disposed(by: disposeBag)

        viewModel.eventStatusItemCheckRangeLabel
            .bind(to: rangeStepperLabel.rx.text)
            .disposed(by: disposeBag)

        // Next event font size

        let fontSizeLabel = Label(text: Strings.Settings.MenuBar.fontSize, font: .systemFont(ofSize: 13))
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
            NSStackView(views: [showNextEventCheckbox, .spacer, rangeStepperLabel, nextEventRangeStepper]),
            NSStackView(views: [fontSizeLabel, .spacer, fontSizeStepperLabel, nextEventFontSizeStepper]),
            nextEventLengthView,
            nextEventDetectNotchCheckbox,
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

        firstWeekdayPrev.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        firstWeekdayNext.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)

        return NSStackView(views: [
            NSStackView(views: [
                NSImageView(image: Icons.Settings.zoomOut),
                calendarScalingSlider,
                NSImageView(image: Icons.Settings.zoomIn)
            ]),
            .dummy,
            NSStackView(views: [firstWeekdayPrev, highlightedWeekdaysButtons, firstWeekdayNext])
                .with(distribution: .fillProportionally),
            .dummy,
            showWeekNumbersCheckbox,
            NSStackView(views: [showDeclinedEventsCheckbox, showDeclinedEventsTooltip]),
            preserveSelectedDateCheckbox
        ])
        .with(orientation: .vertical)
    }()

    let finishedLabel = Label(text: "\(Strings.Settings.Events.finished):", font: .systemFont(ofSize: 13))

    private lazy var eventsContent: NSView = {
        NSStackView(views: [finishedLabel, .spacer, fadePastEventsRadio, hidePastEventsRadio])
    }()

    private func setUpBindings() {
        setUpMenuBar()
        setUpNextEvent()
        setUpCalendar()
        setUpEvents()
        setUpTransparency()
    }

    private func setUpMenuBar() {

        bind(
            control: autoLaunchCheckbox,
            observable: viewModel.autoLaunch,
            observer: viewModel.toggleAutoLaunch
        )

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
            control: showMenuBarBackgroundCheckbox,
            observable: viewModel.showStatusItemBackground,
            observer: viewModel.toggleStatusItemBackground
        )

        setUpIconStyle()

        setUpDateFormat()
    }

    private func setUpIconStyle() {

        let iconStyleControl = iconStyleDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        Observable.combineLatest(
            viewModel.iconStyleOptions, iconStyleControl.skip(1)
        )
        .map { $0[$1].style }
        .bind(to: viewModel.statusItemIconStyleObserver)
        .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.iconStyleOptions, viewModel.statusItemIconStyle
        )
        .bind { [dropdown = iconStyleDropdown] options, iconStyle in
            let menu = NSMenu()
            for option in options {
                let item = NSMenuItem()
                item.title = " "
                item.image = option.image
                menu.addItem(item)
            }
            dropdown.menu = menu
            dropdown.selectItem(at: options.firstIndex(where: { $0.style == iconStyle }) ?? 0)
        }
        .disposed(by: disposeBag)

        viewModel.showStatusItemIcon
            .map(!)
            .bind(to: iconStyleDropdown.rx.isHidden)
            .disposed(by: disposeBag)
    }

    private func setUpDateFormat() {

        let dateFormatControl = dateFormatDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        Observable.combineLatest(
            viewModel.dateFormatOptions, dateFormatControl.skip(1)
        )
        .map { $0[$1].style }
        .bind(to: viewModel.statusItemDateStyleObserver)
        .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.dateFormatOptions, viewModel.statusItemDateStyle
        )
        .bind { [dropdown = dateFormatDropdown] options, dateStyle in
            dropdown.removeAllItems()
            dropdown.addItems(withTitles: options.map(\.title))
            dropdown.selectItem(at: dateStyle.isCustom ? dropdown.numberOfItems - 1: options.firstIndex(where: { $0.style == dateStyle }) ?? 0)
        }
        .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .map(!)
            .bind(to: dateFormatDropdown.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .map(true)
            .bind(to: view.rx.needsLayout)
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

    private func setUpNextEvent() {

        bind(
            control: showNextEventCheckbox,
            observable: viewModel.showEventStatusItem,
            observer: viewModel.toggleEventStatusItem
        )

        viewModel.eventStatusItemLength
            .bind(to: nextEventLengthSlider.rx.integerValue)
            .disposed(by: disposeBag)

        nextEventLengthSlider.rx.value
            .skip(1)
            .map(Int.init)
            .bind(to: viewModel.eventStatusItemLengthObserver)
            .disposed(by: disposeBag)

        bind(
            control: nextEventDetectNotchCheckbox,
            observable: viewModel.eventStatusItemDetectNotch,
            observer: viewModel.toggleEventStatusItemDetectNotch
        )
    }

    private func setUpCalendar() {

        viewModel.calendarScaling
            .bind(to: calendarScalingSlider.rx.doubleValue)
            .disposed(by: disposeBag)

        calendarScalingSlider.rx.value
            .skip(1)
            .bind(to: viewModel.calendarScalingObserver)
            .disposed(by: disposeBag)

        setUpfirstWeekday()
        setUpHighlightedWeekdays()

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
    }

    private func setUpfirstWeekday() {

        firstWeekdayPrev.rx.tap
            .bind(to: viewModel.firstWeekdayPrevObserver)
            .disposed(by: disposeBag)

        firstWeekdayNext.rx.tap
            .bind(to: viewModel.firstWeekdayNextObserver)
            .disposed(by: disposeBag)
    }

    private func makeWeekDayButton(weekDay: WeekDay) -> NSButton {

        let button = CursorButton(cursor: .pointingHand)
        button.title = weekDay.title
        button.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        button.refusesFirstResponder = true
        button.bezelStyle = .recessed
        button.setButtonType(.pushOnPushOff)

        bind(
            control: button,
            observable: viewModel.highlightedWeekdays.map { $0.contains(weekDay.index) },
            observer: viewModel.toggleHighlightedWeekday.mapObserver { _ in weekDay.index }
        )

        return button
    }

    private func setUpHighlightedWeekdays() {

        viewModel.highlightedWeekdaysOptions
            .distinctUntilChanged { $0.map(\.title) }
            .map { [weak self] in
                $0.compactMap { self?.makeWeekDayButton(weekDay: $0) }
            }
            .bind(to: highlightedWeekdaysButtons.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }

    private func setUpEvents() {

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
    }

    private func setUpTransparency() {

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

private extension NSSlider {

    static func make(minValue: Double, maxValue: Double, numberOfTickMarks: Int) -> NSSlider {
        let slider = NSSlider(value: 0, minValue: minValue, maxValue: maxValue, target: nil, action: nil)
        slider.allowsTickMarkValuesOnly = true
        slider.numberOfTickMarks = numberOfTickMarks
        slider.controlSize = .small
        slider.refusesFirstResponder = true
        return slider
    }
}
