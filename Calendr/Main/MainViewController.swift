//
//  MainViewController.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa
import RxSwift

class MainViewController: NSViewController, NSPopoverDelegate {

    // ViewControllers
    private let settingsViewController: SettingsViewController

    // Views
    private let mainStatusItem: NSStatusItem
    private let eventStatusItem: NSStatusItem
    private let mainStackView = NSStackView()
    private let nextEventView: NextEventView
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
    private let calendarPickerViewModel: CalendarPickerViewModel
    private let eventListViewModel: EventListViewModel

    // Reactive
    private let disposeBag = DisposeBag()
    private var popoverDisposeBag = DisposeBag()
    private let dateClick = PublishSubject<Date>()
    private let initialDate: BehaviorSubject<Date>
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

        initialDate = BehaviorSubject(value: dateProvider.now)

        mainStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        mainStatusItem.autosaveName = "main_status_item"
        mainStatusItem.behavior = .terminationOnRemoval
        mainStatusItem.isVisible = true

        eventStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        eventStatusItem.autosaveName = "event_status_item"

        settingsViewModel = SettingsViewModel(
            autoLauncher: autoLauncher,
            dateProvider: dateProvider,
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )

        statusItemViewModel = StatusItemViewModel(
            dateObservable: initialDate,
            settings: settingsViewModel,
            dateProvider: dateProvider,
            screenProvider: screenProvider,
            notificationCenter: notificationCenter
        )

        calendarPickerViewModel = CalendarPickerViewModel(
            calendarService: calendarService,
            userDefaults: userDefaults
        )

        settingsViewController = SettingsViewController(
            settingsViewModel: settingsViewModel,
            calendarsViewModel: calendarPickerViewModel,
            notificationCenter: notificationCenter
        )

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
            clickObserver: dateClick.asObserver()
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
            settings: settingsViewModel,
            enabledCalendars: calendarPickerViewModel.enabledCalendars,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            screenProvider: screenProvider,
            isShowingDetails: isShowingDetails.asObserver(),
            scheduler: MainScheduler.instance
        )

        nextEventView = NextEventView(viewModel: nextEventViewModel)

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()

        setUpSettings()

        setUpMainStatusItem()

        setUpEventStatusItem()

        setUpKeyboard()

        calendarService.requestAccess()
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
        .map { [dateProvider] in dateProvider.now }
        .bind(to: initialDate)
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

        calendarBtn.rx.tap.bind { [workspace] in
            if let appUrl = workspace.urlForApplication(toOpen: URL(string: "webcal://")!) {
                workspace.open(appUrl)
            }
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

        settingsMenu.addItem(withTitle: Strings.Settings.title, action: #selector(openSettings), keyEquivalent: "")

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

    private func setUpPopover(_ popover: NSPopover) {

        popover.contentViewController = self
        popover.delegate = self

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

        notification.popover.animates = false

        setUpAutoClose()
    }

    func popoverWillClose(_ notification: Notification) {

        notification.popover.animates = true

        NSEvent.removeMonitor(mouseMovedEventMonitor!)
    }

    private var contentSize: CGSize {
        var size = view.frame.size
        size.height = mainStackView.frame.height + 2 * Constants.MainStackView.margin
        return size
    }

    // 🔨 Dirty hack to force a layout pass before showing the popover
    private func forceLayout() {

        let wctrl = NSWindowController(window: NSWindow(contentViewController: self))
        wctrl.showWindow(nil)
        wctrl.close()

        view.window?.setContentSize(contentSize)
    }

    private func setUpMainStatusItem() {

        guard let statusBarButton = mainStatusItem.button else { return }

        statusBarButton.rx.tap
            .enumerated()
            .flatMapFirst { [weak self] pass, _ -> Observable<Void> in
                guard let self else { return .empty() }

                self.forceLayout()

                let popover = NSPopover()
                self.setUpPopover(popover)
                popover.show(relativeTo: .zero, of: statusBarButton, preferredEdge: .maxY)

                return popover.rx.deallocated
            }
            .bind { [weak self] in
                self?.popoverDisposeBag = DisposeBag()
            }
            .disposed(by: disposeBag)

        statusBarButton.sendAction(on: .leftMouseDown)

        mainStackView.rx.observe(\.frame)
            .map(\.height)
            .distinctUntilChanged()
            .bind { [weak self] _ in
                guard let self, let window = self.view.window, window.isVisible else { return }

                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    context.allowsImplicitAnimation = true
                    window.setContentSize(self.contentSize)
                }
            }
            .disposed(by: disposeBag)

        statusItemViewModel.text
            .bind(to: statusBarButton.rx.attributedTitle)
            .disposed(by: disposeBag)

        statusItemViewModel.image
            .bind(to: statusBarButton.rx.image)
            .disposed(by: disposeBag)
    }

    private func setUpEventStatusItem() {
        guard
            let statusBarButton = eventStatusItem.button,
            let container = statusBarButton.superview?.superview
        else { return }

        container.addSubview(nextEventView)

        nextEventView.leading(equalTo: statusBarButton, constant: -5)
        nextEventView.top(equalTo: statusBarButton)
        nextEventView.bottom(equalTo: statusBarButton)

        nextEventView.widthObservable
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: eventStatusItem.rx.length)
            .disposed(by: disposeBag)

        settingsViewModel.showEventStatusItem
            .distinctUntilChanged()
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: eventStatusItem.rx.isVisible)
            .disposed(by: disposeBag)

        statusBarButton.rx.tap
            .withUnretained(self)
            .flatMapFirst { (self, _) in self.isShowingDetails.filter(!).take(1).void() }
            .compactMap { [nextEventViewModel] in nextEventViewModel.makeDetails() }
            .skipNil()
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

        statusBarButton.sendAction(on: .leftMouseDown)
    }

    private func setUpKeyboard() {

        keyboard.handler = { [weak self] event -> NSEvent? in
            guard
                let self,
                (try? self.isShowingDetails.value()) == false,
                let key = Keyboard.Key.from(event)
            else { return event }

            if let vc = self.presentedViewControllers?.last {
                guard key ~= .escape else { return event }
                self.dismiss(vc)
                return .none
            }

            switch key {
            case .command("q"):
                NSApp.terminate(nil)

            case .command("f"):
                self.showSearchInput()

            case .escape where self.searchInput.hasFocus:
                self.hideSearchInput()

            case .arrow(let arrow) where !self.searchInput.hasFocus:
                self.arrowSubject.onNext(arrow)

            default:
                return event
            }

            return .none
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
            initial: initialDate,
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

private enum Constants {

    enum MainStackView {
        static let margin: CGFloat = 8
    }
}
