//
//  GeneralSettingsViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import Cocoa
import RxSwift

class GeneralSettingsViewController: NSViewController, SettingsUI {

    private let disposeBag = DisposeBag()

    private let viewModel: SettingsViewModel

    // Menu Bar
    private let autoLaunchCheckbox = Checkbox(title: Strings.Settings.MenuBar.autoLaunch)
    private let showMenuBarIconCheckbox = Checkbox(title: Strings.Settings.MenuBar.showIcon)
    private let showMenuBarDateCheckbox = Checkbox(title: Strings.Settings.MenuBar.showDate)
    private let showMenuBarBackgroundCheckbox = Checkbox(title: Strings.Settings.MenuBar.showBackground)
    private let iconStyleDropdown = Dropdown()
    private let dateFormatDropdown = Dropdown()
    private let dateFormatTextField = NSTextField()
    private let showNextEventCheckbox = Checkbox(title: Strings.Settings.NextEvent.showNextEvent)
    private let nextEventRangeStepper = NSStepper()

    // Calendar
    private let firstWeekdayPrev = ImageButton(image: Icons.Settings.prev)
    private let firstWeekdayNext = ImageButton(image: Icons.Settings.next)
    private let highlightedWeekdaysButtons = NSStackView()
    private let showWeekNumbersCheckbox = Checkbox(title: Strings.Settings.Calendar.showWeekNumbers)
    private let showDeclinedEventsCheckbox = Checkbox(title: Strings.Settings.Calendar.showDeclinedEvents)
    private let preserveSelectedDateCheckbox = Checkbox(title: Strings.Settings.Calendar.preserveSelectedDate)

    // Events
    private let showMapCheckbox = Checkbox(title: Strings.Settings.Events.showMap)
    private let fadePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.fade)
    private let hidePastEventsRadio = Radio(title: Strings.Settings.Events.Finished.hide)

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

        let stackView = NSStackView(
            views: Sections.create([
                makeSection(title: Strings.Settings.menuBar, content: menuBarContent),
                makeSection(title: Strings.Settings.calendar, content: calendarContent),
                makeSection(title: Strings.Settings.events, content: eventsContent),
            ])
            .disposed(by: disposeBag)
        )
        .with(spacing: Constants.contentSpacing)
        .with(orientation: .vertical)

        stackView.setHuggingPriority(.defaultHigh, for: .horizontal)
        stackView.setHuggingPriority(.required, for: .vertical)

        view.addSubview(stackView)

        stackView.edges(equalTo: view)

        iconStyleDropdown.height(equalTo: showMenuBarIconCheckbox)

        dateFormatDropdown.width(equalTo: 150)

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

        dateFormatDropdown.isBordered = false

        dateFormatTextField.placeholderString = viewModel.dateFormatPlaceholder
        dateFormatTextField.refusesFirstResponder = true
        dateFormatTextField.focusRingType = .none

        iconStyleDropdown.isBordered = false
        iconStyleDropdown.setContentHuggingPriority(.required, for: .horizontal)

        let iconStyle = NSStackView(views: [
            showMenuBarIconCheckbox,
            iconStyleDropdown
        ])

        let dateFormat = NSStackView(
            views: [
                showMenuBarDateCheckbox,
                NSStackView(views: [
                    dateFormatDropdown,
                    dateFormatTextField
                ])
                .with(orientation: .vertical),
            ])
            .with(alignment: .top)

        return NSStackView(views: [
            autoLaunchCheckbox,
            iconStyle,
            dateFormat,
            showMenuBarBackgroundCheckbox,
            nextEventContent
        ])
        .with(orientation: .vertical)
    }()

    private lazy var nextEventContent: NSView = {

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

        // Next event stack view

        return NSStackView(views: [showNextEventCheckbox, .spacer, rangeStepperLabel, nextEventRangeStepper])
    }()

    private lazy var showDeclinedEventsTooltip: NSView = {

        let tooltipViewController = NSViewController()
        let view = NSView()
        tooltipViewController.view = view
        let label = Label(text: Strings.Settings.Calendar.showDeclinedEventsTooltip)
        label.preferredMaxLayoutWidth = 190
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        view.addSubview(label)
        label.edges(equalTo: view, margin: 8)

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
        NSStackView(views: [
            showMapCheckbox,
            .dummy,
            NSStackView(views: [finishedLabel, .spacer, fadePastEventsRadio, hidePastEventsRadio])
        ]).with(orientation: .vertical)
    }()

    private func setUpBindings() {
        setUpMenuBar()
        setUpCalendar()
        setUpEvents()
    }

    private func setUpMenuBar() {

        bind(
            control: autoLaunchCheckbox,
            observable: viewModel.autoLaunch,
            observer: viewModel.toggleAutoLaunch
        )
        .disposed(by: disposeBag)

        bind(
            control: showMenuBarIconCheckbox,
            observable: viewModel.showStatusItemIcon,
            observer: viewModel.toggleStatusItemIcon
        )
        .disposed(by: disposeBag)

        bind(
            control: showMenuBarDateCheckbox,
            observable: viewModel.showStatusItemDate,
            observer: viewModel.toggleStatusItemDate
        )
        .disposed(by: disposeBag)

        bind(
            control: showMenuBarBackgroundCheckbox,
            observable: viewModel.showStatusItemBackground,
            observer: viewModel.toggleStatusItemBackground
        )
        .disposed(by: disposeBag)

        bind(
            control: showNextEventCheckbox,
            observable: viewModel.showEventStatusItem,
            observer: viewModel.toggleEventStatusItem
        )
        .disposed(by: disposeBag)

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
            .bind(to: dateFormatDropdown.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.showStatusItemDate
            .bind(to: dateFormatTextField.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .map(!)
            .bind(to: dateFormatTextField.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.isDateFormatInputVisible
            .map { $0 ? .left : .right }
            .bind(to: dateFormatDropdown.rx.alignment)
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

    private func setUpCalendar() {

        setUpfirstWeekday()
        setUpHighlightedWeekdays()

        bind(
            control: showWeekNumbersCheckbox,
            observable: viewModel.showWeekNumbers,
            observer: viewModel.toggleWeekNumbers
        )
        .disposed(by: disposeBag)

        bind(
            control: showDeclinedEventsCheckbox,
            observable: viewModel.showDeclinedEvents,
            observer: viewModel.toggleDeclinedEvents
        )
        .disposed(by: disposeBag)

        bind(
            control: preserveSelectedDateCheckbox,
            observable: viewModel.preserveSelectedDate,
            observer: viewModel.togglePreserveSelectedDate
        )
        .disposed(by: disposeBag)
    }

    private func setUpfirstWeekday() {

        firstWeekdayPrev.rx.tap
            .bind(to: viewModel.firstWeekdayPrevObserver)
            .disposed(by: disposeBag)

        firstWeekdayNext.rx.tap
            .bind(to: viewModel.firstWeekdayNextObserver)
            .disposed(by: disposeBag)
    }

    private func makeWeekDayButton(weekDay: WeekDay) -> DisposableWrapper<NSButton> {

        let button = CursorButton(cursor: .pointingHand)
        button.title = weekDay.title
        button.font = .monospacedSystemFont(ofSize: 11, weight: .semibold)
        button.refusesFirstResponder = true
        button.bezelStyle = .accessoryBar
        button.setButtonType(.pushOnPushOff)

        let disposable = bind(
            control: button,
            observable: viewModel.highlightedWeekdays.map { $0.contains(weekDay.index) },
            observer: viewModel.toggleHighlightedWeekday.mapObserver { _ in weekDay.index }
        )

        return .init(value: button, disposable: disposable)
    }

    private func setUpHighlightedWeekdays() {

        var weekDaysDisposeBag: DisposeBag!

        viewModel.highlightedWeekdaysOptions
            .distinctUntilChanged { $0.map(\.title) }
            .map { [weak self] in
                weekDaysDisposeBag = DisposeBag()
                return $0.compactMap {
                    self?.makeWeekDayButton(weekDay: $0).disposed(by: weekDaysDisposeBag)
                }
            }
            .bind(to: highlightedWeekdaysButtons.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }

    private func setUpEvents() {

        bind(
            control: showMapCheckbox,
            observable: viewModel.showMap,
            observer: viewModel.toggleMap
        )
        .disposed(by: disposeBag)

        bind(
            control: fadePastEventsRadio,
            observable: viewModel.showPastEvents,
            observer: viewModel.togglePastEvents
        )
        .disposed(by: disposeBag)

        bind(
            control: hidePastEventsRadio,
            observable: viewModel.showPastEvents.map(!),
            observer: viewModel.togglePastEvents.mapObserver(!)
        )
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
