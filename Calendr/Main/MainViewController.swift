//
//  MainViewController.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa
import RxSwift
import KeyboardShortcuts

class MainViewController: NSViewController, NSPopoverDelegate {

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
    private let selectedDate = PublishSubject<Date>()
    private let isShowingDetails = BehaviorSubject<Bool>(value: false)
    private let searchInputText = BehaviorSubject<String>(value: "")
    private let arrowSubject = PublishSubject<Keyboard.Key.Arrow>()

    // Properties
    private let keyboard = Keyboard()
    private let workspace: WorkspaceServiceProviding
    private let calendarService: CalendarServiceProviding
    private let dateProvider: DateProviding
    private let screenProvider: ScreenProviding
    private let notificationCenter: NotificationCenter
    private var mouseMovedEventMonitor: Any?

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

        let heightConstraint = mainStackView
            .heightAnchor.constraint(lessThanOrEqualToConstant: 0)
            .activate()

        screenProvider.screenObservable
            .map { 0.9 * $0.visibleFrame.height }
            .bind(to: heightConstraint.rx.constant)
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

        settingsMenu.addItem(withTitle: Strings.Settings.title, action: #selector(openSettings), keyEquivalent: ",")

        settingsMenu.addItem(.separator())

        let pickerMenuItem = settingsMenu.addItem(withTitle: Strings.Settings.Tab.calendars, action: nil, keyEquivalent: "")
        let pickerSubmenu = NSMenu()
        let pickerSubmenuItem = NSMenuItem()
        pickerSubmenu.addItem(pickerSubmenuItem)
        pickerMenuItem.submenu = pickerSubmenu

        let pickerViewController = CalendarPickerViewController(viewModel: calendarPickerViewModel, configuration: .picker)
        pickerSubmenuItem.view = pickerViewController.view.forAutoLayout()
        addChild(pickerViewController)

        settingsMenu.addItem(withTitle: Strings.search, action: #selector(showSearchInput), keyEquivalent: "f")

        settingsMenu.addItem(.separator())

        settingsMenu.addItem(withTitle: Strings.quit, action: #selector(NSApp.terminate), keyEquivalent: "q")

        settingsBtn.rx.tap.bind { [settingsBtn] in
            settingsMenu.popUp(positioning: nil, at: .init(x: 0, y: settingsBtn.frame.height), in: settingsBtn)
        }
        .disposed(by: disposeBag)
    }

    @objc private func openSettings() {

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

    private func setUpAndShow(_ popover: NSPopover, from button: NSStatusBarButton) {

        popover.contentViewController = self
        popover.delegate = self
        popover.animates = false

        settingsViewController.rx.viewWillAppear
            .map(.applicationDefined)
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
            .map { $0 == .on ? .applicationDefined : .transient }
            .bind(to: popover.rx.behavior)
            .disposed(by: popoverDisposeBag)

        screenProvider.screenObservable
            .withUnretained(popover) { p, _ in p }
            .filter(\.animates.isFalse)
            .bind {
                $0.show(relativeTo: .zero, of: button, preferredEdge: .maxY)
            }
            .disposed(by: popoverDisposeBag)
    }

    private func setUpAutoClose() {

        mouseMovedEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [view] event in

            if !NSMouseInRect(NSEvent.mouseLocation, NSScreen.main!.frame, false) {
                view.window?.performClose(nil)
            }
            return event
        }
    }

    func popoverWillShow(_ notification: Notification) {

        setUpAutoClose()
    }

    func popoverWillClose(_ notification: Notification) {

        notification.popover.animates = true

        NSEvent.removeMonitor(mouseMovedEventMonitor!)
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        guard let window = view.window, window.isVisible else { return }

        window.setContentSize(contentSize)
    }

    private var contentSize: CGSize {
        var size = view.frame.size
        size.height = ceil(mainStackView.frame.height + 2 * Constants.MainStackView.margin)
        return size
    }

    // 🔨 Dirty hack to force a layout pass before showing the popover
    private func forceLayout() {

        let wctrl = NSWindowController(window: NSWindow(contentViewController: self))
        wctrl.window?.orderFrontRegardless()
        wctrl.close()

        view.window?.setContentSize(contentSize)
    }

    private let mainStatusItemClickHandler = StatusItemClickHandler()

    private func setUpMainStatusItem() {

        guard let statusBarButton = mainStatusItem.button else { return }

        let clickHandler = mainStatusItemClickHandler

        clickHandler.leftClick
            .flatMapFirst { [weak self] _ -> Observable<Void> in
                guard let self else { return .empty() }

                forceLayout()

                let popover = NSPopover()
                setUpAndShow(popover, from: statusBarButton)

                return popover.rx.deallocated
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

        mainStackView.rx.observe(\.frame)
            .bind { [weak self] _ in
                guard let self, let window = view.window, window.isVisible else { return }
                view.frame.size = contentSize
            }
            .disposed(by: disposeBag)

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
            .withUnretained(self)
            .flatMapFirst { (self, _) in self.isShowingDetails.filter(!).take(1).void() }
            .compactMap { viewModel.makeDetailsViewModel() }
            .flatMapFirst { viewModel -> Observable<Void> in
                let vc = EventDetailsViewController(viewModel: viewModel)
                let popover = NSPopover()
                popover.behavior = .transient
                popover.contentViewController = vc
                popover.delegate = vc
                popover.show(relativeTo: .zero, of: statusBarButton, preferredEdge: .maxY)
                return popover.rx.deallocated
            }
            .subscribe()
            .disposed(by: disposeBag)

        clickHandler.rightClick
            .compactMap { viewModel.makeContextMenuViewModel() }
            .bind { makeContextMenu($0).show(in: statusBarButton) }
            .disposed(by: disposeBag)

        statusBarButton.setUpClickHandler(clickHandler)
    }

    private func setUpKeyboard() {

        keyboard.handler = { [weak self] event -> NSEvent? in
            guard
                let self,
                (try? isShowingDetails.value()) == false,
                let key = Keyboard.Key.from(event)
            else { return event }

            if let vc = presentedViewControllers?.last {
                guard key ~= .escape else { return event }
                dismiss(vc)
                return .none
            }

            switch key {
            case .command("q"):
                NSApp.terminate(nil)

            case .command("f"):
                showSearchInput()

            case .command(","):
                openSettings()

            case .escape where searchInput.hasFocus:
                hideSearchInput()

            case .arrow(let arrow) where !searchInput.hasFocus:
                arrowSubject.onNext(arrow)

            default:
                return event
            }

            return .none
        }

        // Global shortcut
        KeyboardShortcuts.onKeyUp(for: .showMainPopover) { [weak self] in
            guard let self else { return }
            if let window = view.window {
                window.performClose(nil)
                return
            }
            mainStatusItemClickHandler.leftClick.onNext(())
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

        let keyLeft = arrowSubject.matching(.left).void()
        let keyRight = arrowSubject.matching(.right).void()
        let keyDown = arrowSubject.matching(.down).void()
        let keyUp = arrowSubject.matching(.up).void()

        let dateSelector = DateSelector(
            calendar: dateProvider.calendar,
            initial: refreshDate.map { [dateProvider] in dateProvider.now },
            selected: selectedDate,
            reset: resetBtn.rx.tap.asObservable(),
            prevDay: keyLeft,
            nextDay: keyRight,
            prevWeek: keyUp,
            nextWeek: keyDown,
            prevMonth: prevBtn.rx.tap.asObservable(),
            nextMonth: nextBtn.rx.tap.asObservable()
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
        popUp(positioning: nil, at: .init(x: 0, y: view.frame.height + 5), in: view)
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
