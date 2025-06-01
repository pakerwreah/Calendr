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

    // Next Event
    private let showNextEventCheckbox = Checkbox(title: Strings.Settings.NextEvent.showNextEvent)
    private let nextEventRangeStepperLabel = Label()
    private let nextEventRangeStepper = NSStepper()
    private let nextEventGrabAttentionLabel = Label(text: Strings.Settings.NextEvent.grabAttention)
    private let nextEventFlashingCheckbox = Checkbox(title: Strings.Settings.NextEvent.GrabAttention.flashing)
    private let nextEventSoundCheckbox = Checkbox(title: Strings.Settings.NextEvent.GrabAttention.sound)

    // Calendar
    private let firstWeekdayPrev = ImageButton(image: Icons.Settings.prev)
    private let firstWeekdayNext = ImageButton(image: Icons.Settings.next)
    private let highlightedWeekdaysButtons = NSStackView()
    private let weekCountLabel = Label(text: Strings.Settings.Calendar.weekCount)
    private let weekCountStepperLabel = Label()
    private let weekCountStepper = NSStepper()
    private let showWeekNumbersCheckbox = Checkbox(title: Strings.Settings.Calendar.showWeekNumbers)
    private let showDeclinedEventsCheckbox = Checkbox(title: Strings.Settings.Calendar.showDeclinedEvents)
    private let preserveSelectedDateCheckbox = Checkbox(title: Strings.Settings.Calendar.preserveSelectedDate)
    private let dateHoverOptionCheckbox = Checkbox(title: Strings.Settings.Calendar.dateHoverOption)
    private let calendarAppViewModeLabel = Label(text: Strings.Settings.Calendar.calendarAppViewMode)
    private let calendarAppViewModeDropdown = Dropdown()

    // Events
    private let showMapCheckbox = Checkbox(title: Strings.Settings.Events.showMap)
    private let showFinishedEventsCheckbox = Checkbox(title: Strings.Settings.Events.showFinishedEvents)
    private let showOverdueCheckbox = Checkbox(title: Strings.Settings.Events.showOverdueReminders)
    private let showRecurrenceCheckbox = Checkbox(title: Strings.Settings.Events.showRecurrenceIndicator)
    private let forceLocalTimeZoneCheckbox = Checkbox(title: Strings.Settings.Events.forceLocalTimeZone)

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
                makeSection(title: Strings.Settings.nextEvent, content: nextEventContent),
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
            showMenuBarBackgroundCheckbox
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

        nextEventRangeStepperLabel.font = .systemFont(ofSize: 13)

        // Next event stack view
        let showNextEventStack = NSStackView(views: [showNextEventCheckbox, .spacer, nextEventRangeStepperLabel, nextEventRangeStepper])
        let grabAttentionStack = NSStackView(views: [nextEventFlashingCheckbox, nextEventSoundCheckbox]).with(insets: .init(horizontal: 16))
        return NSStackView(views: [
            showNextEventStack,
            nextEventGrabAttentionLabel,
            grabAttentionStack

        ]).with(orientation: .vertical)
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

        calendarAppViewModeDropdown.isBordered = false
        calendarAppViewModeDropdown.setContentHuggingPriority(.required, for: .horizontal)

        weekCountStepper.minValue = 6
        weekCountStepper.maxValue = 10
        weekCountStepper.valueWraps = false
        weekCountStepper.refusesFirstResponder = true
        weekCountStepper.focusRingType = .none

        return NSStackView(views: [
            NSStackView(views: [firstWeekdayPrev, highlightedWeekdaysButtons, firstWeekdayNext])
                .with(distribution: .fillProportionally),
            .dummy,
            showWeekNumbersCheckbox,
            NSStackView(views: [showDeclinedEventsCheckbox, showDeclinedEventsTooltip]),
            preserveSelectedDateCheckbox,
            dateHoverOptionCheckbox,
            NSStackView(views: [weekCountLabel, .spacer, weekCountStepperLabel, weekCountStepper]),
            NSStackView(views: [calendarAppViewModeLabel, calendarAppViewModeDropdown])
        ])
        .with(orientation: .vertical)
    }()

    private lazy var eventsContent: NSView = {
        NSStackView(views: [
            showMapCheckbox,
            showFinishedEventsCheckbox,
            showOverdueCheckbox,
            showRecurrenceCheckbox,
            forceLocalTimeZoneCheckbox
        ]).with(orientation: .vertical)
    }()

    private func setUpBindings() {
        setUpMenuBar()
        setUpNextEvent()
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

        setUpIconStyle()

        bind(
            control: showMenuBarDateCheckbox,
            observable: viewModel.showStatusItemDate,
            observer: viewModel.toggleStatusItemDate
        )
        .disposed(by: disposeBag)

        setUpDateFormat()

        bind(
            control: showMenuBarBackgroundCheckbox,
            observable: viewModel.showStatusItemBackground,
            observer: viewModel.toggleStatusItemBackground
        )
        .disposed(by: disposeBag)
    }

    private func setUpNextEvent() {

        bind(
            control: showNextEventCheckbox,
            observable: viewModel.showEventStatusItem,
            observer: viewModel.toggleEventStatusItem
        )
        .disposed(by: disposeBag)

        setUpNextEventRangeStepper()

        bind(
            control: nextEventFlashingCheckbox,
            observable: viewModel.eventStatusItemFlashing,
            observer: viewModel.toggleEventStatusItemFlashing
        )
        .disposed(by: disposeBag)

        bind(
            control: nextEventSoundCheckbox,
            observable: viewModel.eventStatusItemSound,
            observer: viewModel.toggleEventStatusItemSound
        )
        .disposed(by: disposeBag)
    }

    private func setUpNextEventRangeStepper() {

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
            .bind(to: nextEventRangeStepperLabel.rx.text)
            .disposed(by: disposeBag)
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
            let width = options.map(\.image.size.width).reduce(0, max)
            for option in options {
                let item = NSMenuItem()
                item.title = " "
                item.image = option.image.with(padding: .init(x: (width - option.image.size.width) / 2, y: 0))
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
        .compactMap { $0[safe: $1]?.style }
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

    private func setUpCalendarAppViewMode() {

        let calendarAppViewModeControl = calendarAppViewModeDropdown.rx.controlProperty(
            getter: \.indexOfSelectedItem,
            setter: { $0.selectItem(at: $1) }
        )

        let options = viewModel.calendarAppViewModeOptions
        calendarAppViewModeDropdown.addItems(withTitles: options.map { "\($0.title) " })

        calendarAppViewModeControl
            .skip(1)
            .map { options[$0].mode }
            .bind(to: viewModel.calendarAppViewModeObserver)
            .disposed(by: disposeBag)

        viewModel.calendarAppViewMode
            .compactMap(options.map(\.mode).firstIndex(of:))
            .bind(to: calendarAppViewModeControl)
            .disposed(by: disposeBag)
    }

    private func setUpCalendar() {

        setUpfirstWeekday()
        setUpHighlightedWeekdays()
        setUpWeekCountStepper()

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

        bind(
            control: dateHoverOptionCheckbox,
            observable: viewModel.dateHoverOption,
            observer: viewModel.toggleDateHoverOption
        )
        .disposed(by: disposeBag)

        setUpCalendarAppViewMode()
    }

    private func setUpWeekCountStepper() {

        let rangeStepperProperty = weekCountStepper.rx.controlProperty(
            getter: \.integerValue,
            setter: { $0.integerValue = $1 }
        )

        viewModel.weekCount
            .bind(to: rangeStepperProperty)
            .disposed(by: disposeBag)

        rangeStepperProperty
            .bind(to: viewModel.weekCountObserver)
            .disposed(by: disposeBag)

        viewModel.weekCount.map(\.description)
            .bind(to: weekCountStepperLabel.rx.text)
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
            control: showFinishedEventsCheckbox,
            observable: viewModel.showPastEvents,
            observer: viewModel.togglePastEvents
        )
        .disposed(by: disposeBag)

        bind(
            control: showOverdueCheckbox,
            observable: viewModel.showOverdueReminders,
            observer: viewModel.toggleOverdueReminders
        )
        .disposed(by: disposeBag)

        bind(
            control: showRecurrenceCheckbox,
            observable: viewModel.showRecurrenceIndicator,
            observer: viewModel.toggleRecurrenceIndicator
        )
        .disposed(by: disposeBag)

        bind(
            control: forceLocalTimeZoneCheckbox,
            observable: viewModel.forceLocalTimeZone,
            observer: viewModel.toggleForceLocalTimeZone
        )
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
