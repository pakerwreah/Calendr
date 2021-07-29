//
//  MainViewController.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa
import RxSwift
import RxGesture

class MainViewController: NSViewController {

    // ViewControllers
    private let popover = NSPopover()
    private let settingsViewController: SettingsViewController

    // Views
    private let mainStatusItem: NSStatusItem
    private let eventStatusItem: NSStatusItem
    private let nextEventView: NextEventView
    private let calendarView: CalendarView
    private let eventListView: EventListView
    private let titleLabel = Label()
    private let prevBtn = NSButton()
    private let resetBtn = NSButton()
    private let nextBtn = NSButton()
    private let pinBtn = NSButton()
    private let calendarBtn = NSButton()
    private let settingsBtn = NSButton()

    // ViewModels
    private let calendarViewModel: CalendarViewModel
    private let settingsViewModel: SettingsViewModel
    private let statusItemViewModel: StatusItemViewModel
    private let nextEventViewModel: NextEventViewModel
    private let calendarPickerViewModel: CalendarPickerViewModel
    private let eventListViewModel: EventListViewModel

    // Reactive
    private let disposeBag = DisposeBag()
    private let dateClick = PublishSubject<Date>()
    private let initialDate: BehaviorSubject<Date>
    private let selectedDate = PublishSubject<Date>()

    // Properties
    private let workspace: WorkspaceServiceProviding
    private let calendarService: CalendarServiceProviding
    private let dateProvider: DateProviding
    private let notificationCenter: NotificationCenter

    // MARK: - Initalization

    init(
        workspace: WorkspaceServiceProviding,
        calendarService: CalendarServiceProviding,
        dateProvider: DateProviding,
        userDefaults: UserDefaults,
        notificationCenter: NotificationCenter
    ) {

        self.workspace = workspace
        self.calendarService = calendarService
        self.dateProvider = dateProvider
        self.notificationCenter = notificationCenter

        initialDate = BehaviorSubject(value: dateProvider.now)

        mainStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        mainStatusItem.autosaveName = "main_status_item"
        mainStatusItem.behavior = .terminationOnRemoval
        mainStatusItem.isVisible = true

        eventStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        eventStatusItem.autosaveName = "event_status_item"

        settingsViewModel = SettingsViewModel(
            dateProvider: dateProvider,
            userDefaults: userDefaults,
            notificationCenter: notificationCenter
        )

        statusItemViewModel = StatusItemViewModel(
            dateObservable: initialDate,
            settings: settingsViewModel,
            dateProvider: dateProvider,
            notificationCenter: notificationCenter
        )

        calendarPickerViewModel = CalendarPickerViewModel(
            calendarService: calendarService,
            userDefaults: userDefaults
        )

        settingsViewController = SettingsViewController(
            settingsViewModel: settingsViewModel,
            calendarsViewModel: calendarPickerViewModel
        )

        let hoverSubject = PublishSubject<Date?>()

        // prevent getting 2 events while moving between cells
        let hoverObservable = hoverSubject.debounce(.milliseconds(1), scheduler: MainScheduler.instance)

        calendarViewModel = CalendarViewModel(
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
            hoverObserver: hoverSubject.asObserver(),
            clickObserver: dateClick.asObserver()
        )

        let eventsObservable = calendarViewModel.asObservable()
            .compactMap {
                $0.first(where: \.isSelected).flatMap(\.events)
            }
            .distinctUntilChanged()

        eventListViewModel = EventListViewModel(
            dateObservable: selectedDate,
            eventsObservable: eventsObservable,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            settings: settingsViewModel
        )

        eventListView = EventListView(viewModel: eventListViewModel)

        let todayEventsObservable = calendarViewModel.asObservable()
            .compactMap {
                $0.first(where: \.isToday).flatMap(\.events)
            }
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .distinctUntilChanged()

        nextEventViewModel = NextEventViewModel(
            settings: settingsViewModel,
            eventsObservable: todayEventsObservable,
            dateProvider: dateProvider
        )

        nextEventView = NextEventView(viewModel: nextEventViewModel)

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()

        setUpPopover()

        setUpMainStatusItem()

        setUpEventStatusItem()

        calendarService.requestAccess()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {

        view = NSView()

        let mainView = NSStackView(views: [
            makeHeader(),
            calendarView,
            makeToolBar(),
            eventListView
        ])
        .with(orientation: .vertical)
        .with(spacing: 4)

        view.addSubview(mainView)

        let margin: CGFloat = 8

        mainView.width(equalTo: calendarView)
        mainView.top(equalTo: view, constant: margin)
        mainView.leading(equalTo: view, constant: margin)
        mainView.trailing(equalTo: view, constant: margin)

        mainView.rx.observe(\.frame)
            .distinctUntilChanged()
            .observe(on: MainScheduler.asyncInstance)
            .map { [view] frame in
                var size = view.frame.size
                size.height = frame.height + 2 * margin
                return size
            }
            .bind(to: popover.rx.contentSize)
            .disposed(by: disposeBag)

        let popoverView = view.rx.observe(\.superview)
            .compactMap { $0 as? NSVisualEffectView }
            .take(1)

        Observable.combineLatest(
            popoverView, settingsViewModel.popoverMaterial
        )
        .bind { $0.material = $1 }
        .disposed(by: disposeBag)
    }

    override func viewDidAppear() {

        super.viewDidAppear()
        
        view.window?.makeKey()
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
            rx.viewDidDisappear
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

        calendarBtn.rx.tap.bind { [workspace] in
            if let appUrl = workspace.urlForApplication(toOpen: URL(string: "webcal://")!) {
                workspace.open(appUrl)
            }
        }
        .disposed(by: disposeBag)

        settingsBtn.rx.tap.bind { [weak self, settingsViewController] in
            self?.presentAsModalWindow(settingsViewController)
        }
        .disposed(by: disposeBag)
    }

    private func setUpPopover() {

        popover.rx.observe(\.isShown)
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: popover.rx.animates)
            .disposed(by: disposeBag)

        settingsViewController.rx.viewWillAppear
            .map { .applicationDefined }
            .bind(to: popover.rx.behavior)
            .disposed(by: disposeBag)

        settingsViewController.rx.viewDidDisappear
            .withLatestFrom(pinBtn.rx.state)
            .matching(.off)
            .void()
            .startWith(())
            .map { .transient }
            .bind(to: popover.rx.behavior)
            .disposed(by: disposeBag)

        pinBtn.rx.state
            .map { $0 == .on ? .applicationDefined : .transient }
            .bind(to: popover.rx.behavior)
            .disposed(by: disposeBag)
    }

    private func setUpMainStatusItem() {

        guard let statusBarButton = mainStatusItem.button else { return }

        let menu = NSMenu()
        menu.addItem(withTitle: Strings.quit, action: #selector(NSApp.terminate), keyEquivalent: "q")
        mainStatusItem.menu = menu

        statusBarButton.rx.leftClickGesture()
            .when(.recognized)
            .void()
            .filter { [popover] in
                !popover.isShown
            }
            .bind { [weak self, popover] in
                popover.contentViewController = self
                popover.show(relativeTo: .zero, of: statusBarButton, preferredEdge: .maxY)
            }
            .disposed(by: disposeBag)

        popover.rx.observe(\.isShown)
            .bind(to: statusBarButton.rx.isHighlighted)
            .disposed(by: disposeBag)

        statusItemViewModel.text
            .bind(to: statusBarButton.rx.attributedTitle)
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
            .withLatestFrom(nextEventViewModel.event)
            .skipNil()
            .map { [dateProvider, calendarService, settingsViewModel] event in

                EventDetailsViewModel(
                    event: event,
                    dateProvider: dateProvider,
                    calendarService: calendarService,
                    settings: settingsViewModel
                )
            }
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

    // MARK: - Factories

    private func styleButton(_ button: NSButton) {
        button.size(equalTo: 22)
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.refusesFirstResponder = true
    }

    private func makeHeader() -> NSView {

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .headerTextColor

        [prevBtn, resetBtn, nextBtn].forEach(styleButton)

        prevBtn.image = Icons.Calendar.prev
        resetBtn.image = Icons.Calendar.reset
        nextBtn.image = Icons.Calendar.next

        return NSStackView(views: [
            .spacer(width: 5), titleLabel, .spacer, prevBtn, resetBtn, nextBtn
        ])
        .with(spacing: 0)
    }

    private func makeToolBar() -> NSView {

        [pinBtn, calendarBtn, settingsBtn].forEach(styleButton)

        pinBtn.setButtonType(.toggle)
        pinBtn.image = Icons.Calendar.unpinned
        pinBtn.alternateImage = Icons.Calendar.pinned

        calendarBtn.image = Icons.Calendar.calendar.with(scale: .large)
        settingsBtn.image = Icons.Calendar.settings.with(scale: .large)

        return NSStackView(views: [pinBtn, .spacer, calendarBtn, settingsBtn])
    }

    private func makeDateSelector() -> DateSelector {

        let keySubject = PublishSubject<UInt16>()

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event -> NSEvent? in

            if event.keyCode == 53, let vc = self?.presentedViewControllers?.last {
                self?.dismiss(vc)
                return nil
            }

            if 123...126 ~= event.keyCode {
                keySubject.onNext(event.keyCode)
                return nil
            }

            return event
        }

        let keyLeft = keySubject.matching(123).void()
        let keyRight = keySubject.matching(124).void()
        let keyDown = keySubject.matching(125).void()
        let keyUp = keySubject.matching(126).void()


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
