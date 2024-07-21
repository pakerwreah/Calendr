//
//  MainViewController.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa
import RxSwift
import KeyboardShortcuts

class MainViewController: NSViewController {

    // ViewControllers
    private let settingsViewController: SettingsViewController

    // Views
    private let mainStatusItem: NSStatusItem
    private let eventStatusItem: NSStatusItem
    private let reminderStatusItem: NSStatusItem
    private let mainStackView = NSStackView()
    private let nextEventView: NextEventView
    private let nextReminderView: NextEventView
    private let calendarView: CalendarView
    private let eventListView: EventListView
    private let titleLabel = Label()
    private let searchInput = NSSearchField()
    private let prevBtn = ImageButton()
    private let resetBtn = ImageButton()
    private let nextBtn = ImageButton()
    private let pinBtn = ImageButton()
    private let remindersBtn = ImageButton()
    private let calendarBtn = ImageButton()
    private let settingsBtn = ImageButton()

    // ViewModels
    private let calendarViewModel: CalendarViewModel
    private let settingsViewModel: SettingsViewModel
    private let statusItemViewModel: StatusItemViewModel
    private let nextEventViewModel: NextEventViewModel
    private let nextReminderViewModel: NextEventViewModel
    private let calendarPickerViewModel: CalendarPickerViewModel
    private let eventListViewModel: EventListViewModel

    // Reactive
    private let disposeBag = DisposeBag()
    private var popoverDisposeBag = DisposeBag()
    private let dateClick = PublishSubject<Date>()
    private let dateDoubleClick = PublishSubject<Date>()
    private let refreshDate = PublishSubject<Void>()
    private let selectedDate = BehaviorSubject<Date>(value: .now)
    private let isShowingDetails = BehaviorSubject<Bool>(value: false)
    private let searchInputText = BehaviorSubject<String>(value: "")
    private let navigationSubject = PublishSubject<Keyboard.Key>()

    // Properties
    private let keyboard = Keyboard()
    private let workspace: WorkspaceServiceProviding
    private let calendarService: CalendarServiceProviding
    private let dateProvider: DateProviding
    private let screenProvider: ScreenProviding
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private var heightConstraint: NSLayoutConstraint?

    // MARK: - Initalization

    init(
        autoLauncher: AutoLauncher,
        workspace: WorkspaceServiceProviding,
        calendarService: CalendarServiceProviding,
        dateProvider: DateProviding,
        screenProvider: ScreenProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter
    ) {

        self.workspace = workspace
        self.calendarService = calendarService
        self.dateProvider = dateProvider
        self.screenProvider = screenProvider
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter

        mainStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        mainStatusItem.autosaveName = StatusItemName.main
        mainStatusItem.behavior = .terminationOnRemoval
        mainStatusItem.isVisible = true

        eventStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        eventStatusItem.autosaveName = StatusItemName.event

        reminderStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        reminderStatusItem.autosaveName = StatusItemName.reminder

        settingsViewModel = SettingsViewModel(
            autoLauncher: autoLauncher,
            dateProvider: dateProvider,
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )

        calendarPickerViewModel = CalendarPickerViewModel(
            calendarService: calendarService,
            userDefaults: userDefaults
        )

        let nextEventCalendars = Observable
            .combineLatest(
                calendarPickerViewModel.enabledCalendars,
                calendarPickerViewModel.nextEventCalendars
            )
            .map { $0.filter($1.contains) }

        statusItemViewModel = StatusItemViewModel(
            dateChanged: refreshDate,
            nextEventCalendars: nextEventCalendars,
            settings: settingsViewModel,
            dateProvider: dateProvider,
            screenProvider: screenProvider,
            calendarService: calendarService,
            notificationCenter: notificationCenter,
            scheduler: MainScheduler.instance
        )

        settingsViewController = SettingsViewController(
            settingsViewModel: settingsViewModel,
            calendarsViewModel: calendarPickerViewModel,
            notificationCenter: notificationCenter
        )
        /// Fix weird "conflict with KVO" issue on RxSwift if we present settings
        /// view controller before calling `methodInvoked` at least once.
        /// If we don't do this, the app crashes in `setUpPopover`.
        settingsViewController.rx.viewDidLoad.subscribe().dispose()

        let (hoverObservable, hoverObserver) = PublishSubject<Date?>.pipe()

        calendarViewModel = CalendarViewModel(
            searchObservable: searchInputText,
            dateObservable: selectedDate,
            hoverObservable: hoverObservable,
            enabledCalendars: calendarPickerViewModel.enabledCalendars,
            calendarService: calendarService,
            dateProvider: dateProvider,
            settings: settingsViewModel,
            notificationCenter: notificationCenter
        )

        calendarView = CalendarView(
            viewModel: calendarViewModel,
            hoverObserver: hoverObserver,
            clickObserver: dateClick.asObserver(),
            doubleClickObserver: dateDoubleClick.asObserver()
        )

        let eventListEventsObservable = calendarViewModel.focusedDateEventsObservable
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)

        eventListViewModel = EventListViewModel(
            eventsObservable: eventListEventsObservable,
            isShowingDetails: isShowingDetails,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            settings: settingsViewModel,
            scheduler: WallTimeScheduler()
        )

        eventListView = EventListView(viewModel: eventListViewModel)

        nextEventViewModel = NextEventViewModel(
            type: .event,
            userDefaults: userDefaults,
            settings: settingsViewModel,
            nextEventCalendars: nextEventCalendars,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            screenProvider: screenProvider,
            isShowingDetails: isShowingDetails.asObserver(),
            scheduler: MainScheduler.instance
        )

        nextReminderViewModel = NextEventViewModel(
            type: .reminder,
            userDefaults: userDefaults,
            settings: settingsViewModel,
            nextEventCalendars: nextEventCalendars,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            screenProvider: screenProvider,
            isShowingDetails: isShowingDetails.asObserver(),
            scheduler: MainScheduler.instance
        )

        nextEventView = NextEventView(viewModel: nextEventViewModel)

        nextReminderView = NextEventView(viewModel: nextReminderViewModel)

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()

        setUpSettings()

        setUpMainStatusItem()

        setUpEventStatusItems()

        setUpKeyboard()

        calendarService.requestAccess()

        refreshDate.onNext(())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {

        view = NSView()

        let header = makeHeader()
        let toolBar = makeToolBar()
        let eventList = makeEventList()

        [header, searchInput, calendarView, toolBar, eventList].forEach(mainStackView.addArrangedSubview)

        mainStackView.orientation = .vertical
        let mainStackSpacing: CGFloat = 4
        mainStackView.spacing = mainStackSpacing

        searchInput.focusRingType = .none

        searchInput.rx.observe(\.isHidden)
            .bind { [mainStackView] in
                mainStackView.setCustomSpacing($0 ? 0 : mainStackSpacing, after: header)
            }
            .disposed(by: disposeBag)

        view.addSubview(mainStackView)

        mainStackView.width(equalTo: calendarView)
        mainStackView.top(equalTo: view, constant: Constants.MainStackView.margin)
        mainStackView.leading(equalTo: view, constant: Constants.MainStackView.margin)
        mainStackView.trailing(equalTo: view, constant: Constants.MainStackView.margin)

        heightConstraint = view.height(equalTo: 0).activate()

        let maxHeightConstraint = mainStackView
            .heightAnchor.constraint(lessThanOrEqualToConstant: 0)
            .activate()

        screenProvider.screenObservable
            .map { 0.9 * $0.visibleFrame.height }
            .bind(to: maxHeightConstraint.rx.constant)
            .disposed(by: disposeBag)

        let popoverView = view.rx.observe(\.superview)
            .compactMap { $0 as? NSVisualEffectView }

        Observable.combineLatest(
            popoverView, settingsViewModel.popoverMaterial
        )
        .bind { $0.material = $1 }
        .disposed(by: disposeBag)
    }

    override func viewWillAppear() {

        super.viewWillAppear()

        hideSearchInput()
    }

    override func viewDidAppear() {

        super.viewDidAppear()
        
        view.window?.makeKey()
        NSApp.activate(ignoringOtherApps: true)

        eventListView.scrollTop()
    }

    override func mouseEntered(with event: NSEvent) {

        super.mouseEntered(with: event)

        guard !NSApp.isActive else { return }

        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Setup

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        NSApp.addAccessibilityChild(view)

        view.setAccessibilityIdentifier(Accessibility.Main.view)

        mainStatusItem.button?.setAccessibilityIdentifier(Accessibility.MenuBar.main)
        eventStatusItem.button?.setAccessibilityIdentifier(Accessibility.MenuBar.event)
        reminderStatusItem.button?.setAccessibilityIdentifier(Accessibility.MenuBar.reminder)

        titleLabel.setAccessibilityIdentifier(Accessibility.Main.title)
        prevBtn.setAccessibilityIdentifier(Accessibility.Main.prevBtn)
        resetBtn.setAccessibilityIdentifier(Accessibility.Main.resetBtn)
        nextBtn.setAccessibilityIdentifier(Accessibility.Main.nextBtn)
        pinBtn.setAccessibilityIdentifier(Accessibility.Main.pinBtn)
        remindersBtn.setAccessibilityIdentifier(Accessibility.Main.remindersBtn)
        calendarBtn.setAccessibilityIdentifier(Accessibility.Main.calendarBtn)
        settingsBtn.setAccessibilityIdentifier(Accessibility.Main.settingsBtn)
    }

    private func setUpBindings() {

        makeDateSelector()
            .asObservable()
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: selectedDate)
            .disposed(by: disposeBag)

        Observable.merge(
            notificationCenter.rx.notification(.NSCalendarDayChanged).void(),
            workspace.notificationCenter.rx.notification(NSWorkspace.didWakeNotification).void(),
            rx.viewDidDisappear.withLatestFrom(settingsViewModel.preserveSelectedDate).filter(!).void()
        )
        .bind(to: refreshDate)
        .disposed(by: disposeBag)

        dateClick
            .bind(to: selectedDate)
            .disposed(by: disposeBag)

        calendarViewModel.title
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)

        remindersBtn.rx.tap.bind { [workspace] in
            if let appUrl = workspace.urlForApplication(toOpen: URL(string: "x-apple-reminderkit://")!) {
                workspace.open(appUrl)
            }
        }
        .disposed(by: disposeBag)

        let calendarScript = CalendarScript(workspace: workspace)

        dateDoubleClick
            .bind { date in
                calendarScript.openCalendar(at: date, mode: .day)
            }
            .disposed(by: disposeBag)

        calendarBtn.rx.tap
            .withLatestFrom(selectedDate)
            .bind { date in
                calendarScript.openCalendar(at: date, mode: .month)
            }
            .disposed(by: disposeBag)

        searchInput.rx.text
            .skipNil()
            .bind(to: searchInputText)
            .disposed(by: disposeBag)

        searchInputText
            .bind(to: searchInput.rx.stringValue)
            .disposed(by: disposeBag)
    }

    private func setUpSettings() {

        let settingsMenu = NSMenu()

        settingsMenu.addItem(withTitle: Strings.Settings.title, action: #selector(openSettings), keyEquivalent: ",").target = self

        settingsMenu.addItem(.separator())

        let pickerMenuItem = settingsMenu.addItem(withTitle: Strings.Settings.Tab.calendars, action: nil, keyEquivalent: "")
        let pickerSubmenu = NSMenu()
        let pickerSubmenuItem = NSMenuItem()
        pickerSubmenu.addItem(pickerSubmenuItem)
        pickerMenuItem.submenu = pickerSubmenu

        let pickerViewController = CalendarPickerViewController(viewModel: calendarPickerViewModel, configuration: .picker)
        pickerSubmenuItem.view = pickerViewController.view.forAutoLayout()
        addChild(pickerViewController)

        settingsMenu.addItem(withTitle: Strings.search, action: #selector(showSearchInput), keyEquivalent: "f").target = self

        settingsMenu.addItem(.separator())

        settingsMenu.addItem(withTitle: Strings.quit, action: #selector(NSApp.terminate), keyEquivalent: "q")

        settingsBtn.rx.tap.bind { [settingsBtn] in
            settingsMenu.popUp(positioning: nil, at: .init(x: 0, y: settingsBtn.frame.height), in: settingsBtn)
        }
        .disposed(by: disposeBag)
    }

    @objc private func openSettings() {

        settingsViewController.viewWillAppear()
        presentAsModalWindow(settingsViewController)
    }

    @objc private func showSearchInput() {

        searchInput.isHidden = false
        searchInput.focus()
    }

    private func hideSearchInput() {

        searchInputText.onNext("")
        searchInput.isHidden = true
    }

    private func setUpAndShow(_ popover: Popover, from button: NSStatusBarButton) {

        popover.contentViewController = self

        settingsViewController.rx.viewWillAppear
            .map(.permanent)
            .bind(to: popover.rx.behavior)
            .disposed(by: popoverDisposeBag)

        settingsViewController.rx.viewDidDisappear
            .withLatestFrom(pinBtn.rx.state)
            .matching(.off)
            .void()
            .startWith(())
            .map(.transient)
            .bind(to: popover.rx.behavior)
            .disposed(by: popoverDisposeBag)

        pinBtn.rx.state
            .map { $0 == .on ? .permanent : .transient }
            .bind(to: popover.rx.behavior)
            .disposed(by: popoverDisposeBag)

        popover.show(from: button)
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        heightConstraint?.constant = contentSize.height
    }

    private var contentSize: CGSize {
        var size = view.frame.size
        size.height = ceil(mainStackView.frame.height + 2 * Constants.MainStackView.margin)
        return size
    }

    private let mainStatusItemClickHandler = StatusItemClickHandler()

    private func setUpMainStatusItem() {

        guard let statusBarButton = mainStatusItem.button else { return }

        let clickHandler = mainStatusItemClickHandler

        clickHandler.leftClick
            .flatMapFirst { [weak self] _ -> Observable<Void> in
                guard let self else { return .empty() }

                let popover = Popover()
                setUpAndShow(popover, from: statusBarButton)

                let close = clickHandler.leftClick.bind { [view] in
                    view.window?.performClose(nil)
                }

                return popover.rx.deallocated.do(onNext: { close.dispose() })
            }
            .bind { [weak self] in
                self?.popoverDisposeBag = DisposeBag()
            }
            .disposed(by: disposeBag)

        let menu = NSMenu()

        menu.addItem(withTitle: Strings.Settings.title, action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: Strings.quit, action: #selector(NSApp.terminate), keyEquivalent: "q")

        clickHandler.rightClick.bind {
            menu.show(in: statusBarButton)
        }
        .disposed(by: disposeBag)

        statusBarButton.setUpClickHandler(clickHandler)

        statusItemViewModel.image
            .bind(to: statusBarButton.rx.image)
            .disposed(by: disposeBag)
    }

    private let eventStatusItemClickHandler = StatusItemClickHandler()
    private let reminderStatusItemClickHandler = StatusItemClickHandler()

    private func setUpEventStatusItems() {
        setUpEventStatusItem(item: eventStatusItem, view: nextEventView, viewModel: nextEventViewModel, clickHandler: eventStatusItemClickHandler)
        setUpEventStatusItem(item: reminderStatusItem, view: nextReminderView, viewModel: nextReminderViewModel, clickHandler: reminderStatusItemClickHandler)
    }

    private func setUpEventStatusItem(item: NSStatusItem, view: NextEventView, viewModel: NextEventViewModel, clickHandler: StatusItemClickHandler) {
        guard
            let statusBarButton = item.button,
            let container = statusBarButton.superview?.superview
        else { return }

        container.addSubview(view, positioned: .below, relativeTo: statusBarButton)

        view.leading(equalTo: statusBarButton, constant: -5)
        view.top(equalTo: statusBarButton)
        view.bottom(equalTo: statusBarButton)

        view.widthObservable
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: item.rx.length)
            .disposed(by: disposeBag)

        Observable
            .combineLatest(
                settingsViewModel.showEventStatusItem,
                viewModel.hasEvent
            )
            .map { $0 && $1 }
            .distinctUntilChanged()
            .observe(on: MainScheduler.asyncInstance)
            .bind { showEvent in
                if showEvent {
                    viewModel.restoreStatusItemPreferredPosition()
                    item.isVisible = true
                } else if item.isVisible {
                    viewModel.saveStatusItemPreferredPosition()
                    item.isVisible = false
                }
            }
            .disposed(by: disposeBag)

        clickHandler.leftClick
            .flatMapFirst { _ -> Observable<Void> in
                guard let vm = viewModel.makeDetailsViewModel() else { return .void() }
                let vc = EventDetailsViewController(viewModel: vm)
                let popover = Popover()
                popover.behavior = .transient
                popover.contentViewController = vc
                popover.delegate = vc
                popover.show(from: statusBarButton)

                let close = clickHandler.leftClick.bind {
                    vc.view.window?.performClose(nil)
                }

                return popover.rx.deallocated.do(onNext: { close.dispose() })
            }
            .subscribe()
            .disposed(by: disposeBag)

        clickHandler.rightClick
            .flatMapFirst { _ -> Observable<Void> in
                guard let vm = viewModel.makeContextMenuViewModel() else { return .void() }
                let menu = makeContextMenu(vm)
                menu.show(in: statusBarButton)
                return menu.rx.deallocated
            }
            .subscribe()
            .disposed(by: disposeBag)

        statusBarButton.setUpClickHandler(clickHandler)
    }

    private func setUpKeyboard() {
        setUpLocalShortcuts()
        setUpGlobalShortcuts()
    }

    private func setUpLocalShortcuts() {

        keyboard.listen(in: self) { [weak self] event, key -> NSEvent? in
            guard let self else { return event }

            switch key {
            case .command(.char("q")):
                NSApp.terminate(nil)

            case .command(.char(",")):
                openSettings()

            case .command(.char("p")):
                pinBtn.performClick(nil)

            case .command(.char("f")):
                showSearchInput()

            case .escape where searchInput.hasFocus:
                hideSearchInput()

            case _ where searchInput.hasFocus:
                return event

            // ↓ Search input not focused ↓ //

            case .option(.char("w")):
                userDefaults.showWeekNumbers.toggle()

            case .option(.char("d")):
                userDefaults.showDeclinedEvents.toggle()

            case .arrow, .command(.arrow), .backspace:
                navigationSubject.onNext(key)

            case .enter:
                dateDoubleClick.onNext(selectedDate.value)

            default:
                return event
            }

            return .none
        }
    }

    private func closeModals() {
        NSMenu.closeAll()
        Popover.closeAll()
    }

    private func setUpGlobalShortcuts() {

        KeyboardShortcuts.onKeyUp(for: .showMainPopover) { [weak self] in
            guard let self else { return }
            closeModals()
            mainStatusItemClickHandler.leftClick.onNext(())
        }

        KeyboardShortcuts.onKeyUp(for: .showNextEventPopover) { [weak self] in
            guard let self else { return }
            closeModals()
            eventStatusItemClickHandler.leftClick.onNext(())
        }

        KeyboardShortcuts.onKeyUp(for: .showNextEventOptions) { [weak self] in
            guard let self else { return }
            closeModals()
            eventStatusItemClickHandler.rightClick.onNext(())
        }

        KeyboardShortcuts.onKeyUp(for: .showNextReminderPopover) { [weak self] in
            guard let self else { return }
            closeModals()
            reminderStatusItemClickHandler.leftClick.onNext(())
        }

        KeyboardShortcuts.onKeyUp(for: .showNextReminderOptions) { [weak self] in
            guard let self else { return }
            closeModals()
            reminderStatusItemClickHandler.rightClick.onNext(())
        }
    }

    // MARK: - Factories

    private func makeEventList() -> NSView {

        let scrollView = NSScrollView()

        scrollView.drawsBackground = false
        scrollView.documentView = eventListView

        scrollView.contentView.edges(to: scrollView)
        scrollView.contentView.edges(to: eventListView).bottom.priority = .dragThatCanResizeWindow

        calendarViewModel.cellViewModelsObservable
            .compactMap { $0.first(where: \.isSelected)?.date }
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind { [view = eventListView] _ in
                view.scroll(.init(x: 0, y: view.bounds.height))
            }
            .disposed(by: disposeBag)

        return scrollView
    }

    private func makeHeader() -> NSView {

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .headerTextColor

        [prevBtn, resetBtn, nextBtn].forEach { $0.size(equalTo: 22) }

        prevBtn.image = Icons.Calendar.prev
        resetBtn.image = Icons.Calendar.reset.with(scale: .small)
        nextBtn.image = Icons.Calendar.next

        return NSStackView(views: [
            .spacer(width: 5), titleLabel, .spacer, prevBtn, resetBtn, nextBtn
        ])
        .with(spacing: 0)
    }

    private func makeToolBar() -> NSView {

        [pinBtn, remindersBtn, calendarBtn, settingsBtn].forEach { $0.size(equalTo: 22) }

        pinBtn.setButtonType(.toggle)
        pinBtn.image = Icons.Calendar.unpinned
        pinBtn.alternateImage = Icons.Calendar.pinned

        remindersBtn.image = Icons.Calendar.reminders.with(scale: .large)
        calendarBtn.image = Icons.Calendar.calendar.with(scale: .large)
        settingsBtn.image = Icons.Calendar.settings.with(scale: .large)

        return NSStackView(views: [pinBtn, .spacer, remindersBtn, calendarBtn, settingsBtn])
    }

    private func makeDateSelector() -> DateSelector {

        let backspace = navigationSubject.matching(.backspace).void()

        let keyLeft = navigationSubject.matching(.arrow(.left)).void()
        let keyRight = navigationSubject.matching(.arrow(.right)).void()
        let keyDown = navigationSubject.matching(.arrow(.down)).void()
        let keyUp = navigationSubject.matching(.arrow(.up)).void()

        let cmdUpLeft = navigationSubject.matching(.command(.arrow(.up)), .command(.arrow(.left))).void()
        let cmdDownRight = navigationSubject.matching(.command(.arrow(.down)), .command(.arrow(.right))).void()

        let dateSelector = DateSelector(
            calendar: dateProvider.calendar,
            initial: refreshDate.map { [dateProvider] in dateProvider.now },
            selected: selectedDate,
            reset: .merge(resetBtn.rx.tap.asObservable(), backspace),
            prevDay: keyLeft,
            nextDay: keyRight,
            prevWeek: keyUp,
            nextWeek: keyDown,
            prevMonth: .merge(prevBtn.rx.tap.asObservable(), cmdUpLeft),
            nextMonth: .merge(nextBtn.rx.tap.asObservable(), cmdDownRight)
        )

        return dateSelector
    }
}

private func makeContextMenu(_ viewModel: some ContextMenuViewModel) -> NSMenu {
    ContextMenu(viewModel: viewModel)
}

private enum Constants {

    enum MainStackView {
        static let margin: CGFloat = 8
    }
}

private extension NSMenu {
    
    func show(in view: NSView) {
        DispatchQueue.main.async {
            // this is a blocking operation
            self.popUp(positioning: nil, at: .init(x: 0, y: view.frame.height + 5), in: view)
        }
    }
}

private class StatusItemClickHandler {
    let leftClick = PublishSubject<Void>()
    let rightClick = PublishSubject<Void>()

    @objc func action() {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .leftMouseUp:
            self.leftClick.onNext(())
        case .rightMouseUp:
            self.rightClick.onNext(())
        default:
            break
        }
    }
}

private extension NSStatusBarButton {

    func setUpClickHandler(_ handler: StatusItemClickHandler) {
        sendAction(on: [.leftMouseUp, .rightMouseUp])
        target = handler
        action = #selector(StatusItemClickHandler.action)
    }
}
