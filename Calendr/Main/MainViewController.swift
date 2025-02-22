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
    private lazy var settingsViewController = SettingsViewController(
        settingsViewModel: settingsViewModel,
        calendarsViewModel: calendarPickerViewModel,
        notificationCenter: notificationCenter,
        autoUpdater: autoUpdater
    )

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
    private let searchInputSuggestionView = SearchSuggestionView()
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
    private let selectedDate: BehaviorSubject<Date>
    private let isShowingDetails = BehaviorSubject<Bool>(value: false)
    private let searchInputText = BehaviorSubject<String>(value: "")
    private let searchInputSuggestionDate = BehaviorSubject<DateSuggestionResult?>(value: nil)
    private let navigationSubject = PublishSubject<Keyboard.Key>()
    private let keyboardModifiers = BehaviorSubject<NSEvent.ModifierFlags>(value: [])

    // Properties
    private let keyboard = Keyboard()
    private let deeplink: Observable<URL>
    private let workspace: WorkspaceServiceProviding
    private let calendarService: CalendarServiceProviding
    private let dateProvider: DateProviding
    private let screenProvider: ScreenProviding
    private let autoUpdater: AutoUpdater
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    private var heightConstraint: NSLayoutConstraint?

    // MARK: - Initalization

    init(
        deeplink: Observable<URL>,
        autoLauncher: AutoLauncher,
        workspace: WorkspaceServiceProviding,
        calendarService: CalendarServiceProviding,
        geocoder: GeocodeServiceProviding,
        weatherService: WeatherServiceProviding,
        dateProvider: DateProviding,
        screenProvider: ScreenProviding,
        notificationProvider: LocalNotificationProviding,
        networkProvider: NetworkServiceProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter,
        fileManager: FileManager
    ) {

        self.deeplink = deeplink
        self.workspace = workspace
        self.calendarService = calendarService
        self.dateProvider = dateProvider
        self.selectedDate = .init(value: dateProvider.now)
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
            .share(replay: 1)

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

        autoUpdater = AutoUpdater(
            userDefaults: userDefaults,
            notificationProvider: notificationProvider,
            networkProvider: networkProvider,
            fileManager: fileManager
        )

        let (hoverObservable, hoverObserver) = PublishSubject<Date?>.pipe()

        calendarViewModel = CalendarViewModel(
            searchObservable: searchInputText,
            dateObservable: selectedDate,
            hoverObservable: hoverObservable,
            keyboardModifiers: keyboardModifiers,
            enabledCalendars: calendarPickerViewModel.enabledCalendars,
            calendarService: calendarService,
            dateProvider: dateProvider,
            settings: settingsViewModel
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
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            userDefaults: userDefaults,
            settings: settingsViewModel,
            scheduler: WallTimeScheduler.instance,
            eventsScheduler: WallTimeScheduler.instance
        )

        eventListView = EventListView(viewModel: eventListViewModel)

        nextEventViewModel = NextEventViewModel(
            type: .event,
            userDefaults: userDefaults,
            settings: settingsViewModel,
            nextEventCalendars: nextEventCalendars,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            screenProvider: screenProvider,
            isShowingDetails: isShowingDetails.asObserver(),
            scheduler: MainScheduler.instance,
            soundPlayer: .shared
        )

        nextReminderViewModel = NextEventViewModel(
            type: .reminder,
            userDefaults: userDefaults,
            settings: settingsViewModel,
            nextEventCalendars: nextEventCalendars,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            screenProvider: screenProvider,
            isShowingDetails: isShowingDetails.asObserver(),
            scheduler: MainScheduler.instance,
            soundPlayer: .shared
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

        refreshDate.onNext(())

        setUpDeeplink()

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) { [autoUpdater] in
            autoUpdater.start()
        }

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
        let eventListSummary = makeEventListSummary()
        let eventListScroll = makeEventListScroll()

        rx.viewDidLayout.withLatestFrom(selectedDate).map { [dateProvider, eventListView] date in
            let isToday = dateProvider.calendar.isDateInToday(date)
            let canScroll = eventListView.frame.height > eventListScroll.frame.height
            let isVisible = isToday && canScroll
            return !isVisible
        }
        .bind(to: eventListSummary.rx.isHidden)
        .disposed(by: disposeBag)

        [header, searchInput, calendarView, toolBar, eventListSummary, eventListScroll].forEach(mainStackView.addArrangedSubview)

        mainStackView.orientation = .vertical
        let mainStackSpacing: CGFloat = 4
        mainStackView.spacing = mainStackSpacing

        mainStackView.setCustomSpacing(mainStackSpacing + 2, after: eventListSummary)

        searchInput.focusRingType = .none

        searchInput.rx.observe(\.isHidden)
            .bind { [mainStackView] in
                mainStackView.setCustomSpacing($0 ? 0 : mainStackSpacing, after: header)
            }
            .disposed(by: disposeBag)

        view.addSubview(mainStackView)
        view.addSubview(searchInputSuggestionView)

        searchInputSuggestionView.top(equalTo: searchInput.bottomAnchor)
        searchInputSuggestionView.leading(equalTo: searchInput, constant: 20)
        searchInputSuggestionView.isHidden = true

        mainStackView.width(equalTo: calendarView)
        mainStackView.top(equalTo: view, constant: Constants.MainStackView.margin)
        mainStackView.leading(equalTo: view, constant: Constants.MainStackView.margin)
        mainStackView.trailing(equalTo: view, constant: -Constants.MainStackView.margin)

        heightConstraint = view.height(equalTo: 0)

        let maxHeightConstraint = mainStackView.height(lessThanOrEqualTo: 0)

        screenProvider.screenObservable
            .map { $0.visibleFrame.height - 30 }
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

    // MARK: - Setup

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        NSApp.addAccessibilityChild(view)

        view.setAccessibilityIdentifier(Accessibility.Main.view)

        statusItemViewModel.iconsAndText
            .map { birthday, calendar, text in
                [
                    Accessibility.MenuBar.Main.item,
                    birthday != nil ? Accessibility.MenuBar.Main.Icon.birthday : nil,
                    calendar != nil ? Accessibility.MenuBar.Main.Icon.calendar : nil,
                    text
                ]
                .compact()
            }
            .bind(to: mainStatusItem.button!.rx.accessibilityIdentifiers)
            .disposed(by: disposeBag)

        eventStatusItem.button?.setAccessibilityIdentifier(Accessibility.MenuBar.Event.item)
        reminderStatusItem.button?.setAccessibilityIdentifier(Accessibility.MenuBar.Reminder.item)

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
            .withLatestFrom(
                Observable.combineLatest(selectedDate, settingsViewModel.calendarAppViewMode)
            )
            .bind { [dateProvider] date, mode in
                var date = date
                if mode == .week, let week = dateProvider.calendar.dateInterval(of: .weekOfYear, for: date) {
                    date = week.start
                }
                calendarScript.openCalendar(at: date, mode: mode)
            }
            .disposed(by: disposeBag)

        searchInput.rx.text
            .skipNil()
            .bind(to: searchInputText)
            .disposed(by: disposeBag)

        searchInputText
            .bind(to: searchInput.rx.stringValue)
            .disposed(by: disposeBag)

        setUpDateSuggestion()

        autoUpdater.notificationTap.bind { [weak self] action in
            guard let self else { return }

            switch action {
            case .newVersion(.default):
                openSettingsTab(.about)
            
            case .newVersion(.install):
                autoUpdater.downloadAndInstall()

            case .updated:
                openReleasePage()
            }

        }
        .disposed(by: disposeBag)
    }

    private func setUpDateSuggestion() {

        searchInputText
            .map { [dateProvider] text in
                DateSearchParser.parse(text: text, using: dateProvider)
            }
            .bind(to: searchInputSuggestionDate)
            .disposed(by: disposeBag)

        Observable
            .combineLatest(searchInputSuggestionDate, searchInput.rx.hasFocus)
            .map { suggestion, hasFocus in
                return suggestion == nil || !hasFocus
            }
            .bind(to: searchInputSuggestionView.rx.isHidden)
            .disposed(by: disposeBag)

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .long

        searchInputSuggestionDate
            .compactMap(\.?.date)
            .map(formatter.string(from:))
            .bind(to: searchInputSuggestionView.textField.rx.text)
            .disposed(by: disposeBag)
    }

    private func openReleasePage() {
        workspace.open(URL(string: "https://github.com/pakerwreah/Calendr/releases/latest")!)
    }

    private func setUpSettings() {

        let settingsMenu = TrackedMenu()

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
        openSettingsTab(.general)
    }

    private func openSettingsTab(_ tab: SettingsTab) {

        if !settingsViewModel.isPresented.current {
            settingsViewController.viewWillAppear()
            presentAsModalWindow(settingsViewController)
        }
        settingsViewController.selectedTabViewItemIndex = tab.rawValue
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

        settingsViewModel.isPresented
            .matching(true)
            .map(.permanent)
            .bind(to: popover.rx.behavior)
            .disposed(by: popoverDisposeBag)

        settingsViewModel.isPresented
            .matching(false)
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

                let close = clickHandler.leftClick.bind {
                    Popover.closeAll()
                }

                return popover.rx.deallocated.do(onNext: { close.dispose() })
            }
            .bind { [weak self] in
                self?.popoverDisposeBag = DisposeBag()
            }
            .disposed(by: disposeBag)

        let menu = TrackedMenu()

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
                popover.show(from: statusBarButton, after: vm.optimisticLoadTime)

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

            keyboardModifiers.onNext(event.modifierFlags)

            guard let key else {
                return event
            }

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

            case .enter where searchInput.hasFocus:
                guard let (date, result) = searchInputSuggestionDate.current else {
                    return event
                }
                selectedDate.onNext(date)
                searchInputText.onNext(result)

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
                dateDoubleClick.onNext(selectedDate.current)

            default:
                return event
            }

            return .none
        }
    }

    private func closeModals(completion: @escaping () -> Void) {
        Popover.closeAll()
        TrackedMenu.closeAll {
            completion()
        }
    }

    private func setUpGlobalShortcuts() {

        KeyboardShortcuts.onKeyUp(for: .showMainPopover) { [weak self] in
            self?.closeModals {
                self?.mainStatusItemClickHandler.leftClick.onNext(())
            }
        }

        KeyboardShortcuts.onKeyUp(for: .showNextEventPopover) { [weak self] in
            self?.closeModals {
                self?.eventStatusItemClickHandler.leftClick.onNext(())
            }
        }

        KeyboardShortcuts.onKeyUp(for: .showNextEventOptions) { [weak self] in
            self?.closeModals {
                self?.eventStatusItemClickHandler.rightClick.onNext(())
            }
        }

        KeyboardShortcuts.onKeyUp(for: .showNextReminderPopover) { [weak self] in
            self?.closeModals {
                self?.reminderStatusItemClickHandler.leftClick.onNext(())
            }
        }

        KeyboardShortcuts.onKeyUp(for: .showNextReminderOptions) { [weak self] in
            self?.closeModals {
                self?.reminderStatusItemClickHandler.rightClick.onNext(())
            }
        }
    }

    private func setUpDeeplink() {

        let handleColdStart = mainStatusItem.rx.observe(\.button)
            .skipNil()
            .flatMapLatest { $0.rx.observe(\.frame) }
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .take(1)
            .ignoreElements()
            .asCompletable()

        let date = handleColdStart
            .andThen(deeplink)
            .compactMap { [dateProvider] url -> Date? in
                guard let action = url.host, action == "date" else {
                    return nil
                }
                let result = DateSearchParser.parse(text: url.lastPathComponent, using: dateProvider)
                return result?.date
            }
            .share(replay: 1)

        date.bind(to: selectedDate)
            .disposed(by: disposeBag)

        date.void()
            .filter { [view] in view.window == nil }
            .bind(to: mainStatusItemClickHandler.leftClick)
            .disposed(by: disposeBag)

    }

    // MARK: - Factories

    private func makeEventListSummary() -> NSView {

        let overdueLabel = Label()
        let alldayLabel = Label()
        let todayLabel = Label()

        [overdueLabel, alldayLabel, todayLabel].forEach { label in
            label.font = .systemFont(ofSize: 10)
            label.textColor = .labelColor
            label.lineBreakMode = .byTruncatingMiddle
            label.alignment = .center
            label.setContentHuggingPriority(.required, for: .horizontal)
        }

        let stackView = NSStackView(views: [overdueLabel, alldayLabel, todayLabel])
            .with(distribution: .fillEqually)

        eventListViewModel.asObservable()
            .withLatestFrom(selectedDate) { ($0, $1) }
            .observe(on: MainScheduler.instance)
            .bind { [dateProvider] group, date in
                guard dateProvider.calendar.isDateInToday(date) else {
                    return
                }
                stackView.isHidden = false

                overdueLabel.stringValue = Strings.Reminder.Status.overdue + ": \(group.overdue)"
                overdueLabel.isHidden = group.overdue == 0

                alldayLabel.stringValue = Strings.Event.allDay + ": \(group.allday)"
                alldayLabel.isHidden = group.allday == 0

                todayLabel.stringValue = Strings.Formatter.Date.today + ": \(group.pending)"
                todayLabel.isHidden = group.pending == 0
            }
            .disposed(by: disposeBag)

        return stackView
    }

    private func makeEventListScroll() -> NSView {

        let scrollView = NSScrollView()

        scrollView.drawsBackground = false
        scrollView.documentView = eventListView

        scrollView.contentView.edges(equalTo: scrollView)
        scrollView.contentView.edges(equalTo: eventListView).bottom.priority = .dragThatCanResizeWindow

        rx.viewDidAppear.bind { [eventListView] in
            eventListView.scrollTop()
        }
        .disposed(by: disposeBag)

        eventListViewModel.asObservable()
            .withLatestFrom(selectedDate.asObservable()) { ($0, $1) }
            .repeat(when: rx.viewDidAppear)
            .observe(on: MainScheduler.asyncInstance)
            .bind { [dateProvider, eventListView] groups, date in

                guard !groups.items.isEmpty, scrollView.frame != .zero else { return }

                let isToday = dateProvider.calendar.isDateInToday(date)
                let canScroll = eventListView.bounds.height > scrollView.bounds.height

                guard isToday, canScroll else {
                    eventListView.scrollTop()
                    return
                }

                let index = groups.items.firstIndex {
                    guard
                        case .event(let event) = $0,
                        !event.isAllDay,
                        dateProvider.calendar.isDateInToday(event.start),
                        let isFinished = event.isFaded.lastValue()
                    else {
                        return false
                    }
                    return !isFinished
                } ?? groups.items.count - 1

                guard let rect = eventListView.childRect(at: index) else { return }

                let newOriginY = rect.midY - eventListView.bounds.height + scrollView.bounds.height / 2
                let newOrigin = NSPoint(x: 0, y: newOriginY)

                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.3
                    scrollView.contentView.animator().setBoundsOrigin(newOrigin)
                })
            }
            .disposed(by: disposeBag)

        return scrollView
    }

    private func makeHeader() -> NSView {

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .headerTextColor

        [prevBtn, resetBtn, nextBtn].forEach { $0.size(equalTo: 22) }

        prevBtn.image = Icons.Calendar.prev
        prevBtn.toolTip = Strings.Tooltips.Navigation.prevMonth

        resetBtn.image = Icons.Calendar.reset.with(scale: .small)
        resetBtn.toolTip = Strings.Tooltips.Navigation.today

        nextBtn.image = Icons.Calendar.next
        nextBtn.toolTip = Strings.Tooltips.Navigation.nextMonth

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
        pinBtn.toolTip = Strings.Tooltips.Toolbar.stayOpen

        remindersBtn.image = Icons.Calendar.reminders.with(scale: .large)
        remindersBtn.toolTip = Strings.Tooltips.Toolbar.openReminders

        calendarBtn.image = Icons.Calendar.calendar.with(scale: .large)
        calendarBtn.toolTip = Strings.Tooltips.Toolbar.openCalendar

        settingsBtn.image = Icons.Calendar.settings.with(scale: .large)
        settingsBtn.toolTip = Strings.Tooltips.Toolbar.openMenu

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

        Popover.closeAll()

        guard let screen = view.window?.screen else { return }

        let offsetY = !screen.hasNotch ? view.frame.height + 7 : 0

        DispatchQueue.main.async {
            // this is a blocking operation
            self.popUp(positioning: nil, at: .init(x: 0, y: offsetY), in: view)
        }
    }
}

/**
 We trigger `left` click on mouse `down` and `right` click on mouse `up` on purpose.
 Mouse down feels faster, but NSMenu.popUp blocks the event chain and causes the button to be stuck in a weird state.
 It's not about the highlight effect, it really gets stuck and we have to click it twice for it to work again.
 **/
private class StatusItemClickHandler {
    let leftClick = PublishSubject<Void>()
    let rightClick = PublishSubject<Void>()

    @objc func action() {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .leftMouseDown:
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
        sendAction(on: [.leftMouseDown, .rightMouseUp])
        target = handler
        action = #selector(StatusItemClickHandler.action)
    }
}
