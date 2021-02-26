//
//  MainViewController.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa
import RxSwift
import RxCocoa
import RxGesture

@available(OSX 11.0, *)
class MainViewController: NSViewController {

    // ViewControllers
    private let popover = NSPopover()
    private let settingsViewController: SettingsViewController

    // Views
    private let statusItem: NSStatusItem
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

    // Reactive
    private let disposeBag = DisposeBag()
    private let dateClick = PublishSubject<Date>()
    private let initialDate = BehaviorSubject<Date>(value: Date())
    private let selectedDate = PublishSubject<Date>()

    // Properties
    private let calendarService = CalendarServiceProvider()
    private let workspaceProvider = WorkspaceProvider()
    private let dateProvider = DateProvider(calendar: .autoupdatingCurrent)

    init() {

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.behavior = .terminationOnRemoval
        statusItem.isVisible = true

        eventStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        eventStatusItem.autosaveName = "event_status_item"

        settingsViewModel = SettingsViewModel(
            dateProvider: dateProvider,
            userDefaults: .standard,
            notificationCenter: .default
        )

        statusItemViewModel = StatusItemViewModel(
            dateObservable: initialDate,
            settings: settingsViewModel,
            dateProvider: dateProvider,
            notificationCenter: .default
        )

        calendarPickerViewModel = CalendarPickerViewModel(
            calendarService: calendarService,
            userDefaults: .standard
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
            notificationCenter: .default
        )

        calendarView = CalendarView(
            viewModel: calendarViewModel,
            settings: settingsViewModel,
            hoverObserver: hoverSubject.asObserver(),
            clickObserver: dateClick.asObserver()
        )

        let eventsObservable = calendarViewModel.asObservable()
            .compactMap {
                $0.first(where: \.isSelected).flatMap(\.events)
            }
            .distinctUntilChanged()

        eventListView = EventListView(
            eventsObservable: eventsObservable,
            dateProvider: dateProvider,
            workspaceProvider: workspaceProvider,
            settings: settingsViewModel
        )

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

        setUpBindings()

        setUpPopover()

        setUpStatusItem()

        setUpEventStatusItem()

        calendarService.requestAccess()
    }

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
    }

    private func makeHeader() -> NSView {

        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .headerTextColor

        [prevBtn, resetBtn, nextBtn].forEach(styleButton)

        prevBtn.image = NSImage(named: NSImage.goBackTemplateName)
        resetBtn.image = NSImage(named: NSImage.refreshTemplateName)
        nextBtn.image = NSImage(named: NSImage.goForwardTemplateName)

        return NSStackView(views: [
            .spacer(width: 5), titleLabel, .spacer, prevBtn, resetBtn, nextBtn
        ])
        .with(spacing: 0)
    }

    private func makeToolBar() -> NSView {

        [pinBtn, calendarBtn, settingsBtn].forEach(styleButton)

        pinBtn.setButtonType(.onOff)

        calendarBtn.image = NSImage(named: NSImage.iconViewTemplateName)?.withSymbolConfiguration(.init(scale: .large))
        settingsBtn.image = NSImage(named: NSImage.actionTemplateName)?.withSymbolConfiguration(.init(scale: .large))

        return NSStackView(views: [pinBtn, .spacer, calendarBtn, settingsBtn])
    }

    override func viewDidAppear() {
        view.window?.makeKey()
    }

    private func setUpBindings() {

        makeDateSelector()
            .asObservable()
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: selectedDate)
            .disposed(by: disposeBag)

        Observable.merge(
            NotificationCenter.default.rx.notification(.NSCalendarDayChanged).toVoid(),
            rx.sentMessage(#selector(NSViewController.viewDidDisappear)).toVoid()
        )
        .map { Date() }
        .bind(to: initialDate)
        .disposed(by: disposeBag)

        dateClick
            .bind(to: selectedDate)
            .disposed(by: disposeBag)

        calendarViewModel.title
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposeBag)

        calendarBtn.rx.tap.bind {
            if let appUrl = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "webcal://")!) {
                NSWorkspace.shared.open(appUrl)
            }
        }
        .disposed(by: disposeBag)

        settingsBtn.rx.tap.bind { [weak self, settingsViewController] in
            self?.presentAsModalWindow(settingsViewController)
        }
        .disposed(by: disposeBag)

        let pinIconOn = Self.pinBtnIcon(.on)
        let pinIconOff = Self.pinBtnIcon(.off)

        pinBtn.rx.state.map { $0 == .on ? pinIconOn : pinIconOff }
            .bind(to: pinBtn.rx.attributedTitle)
            .disposed(by: disposeBag)
    }

    private static func pinBtnIcon(_ state: NSControl.StateValue) -> NSAttributedString {
        let imageName = state == .on ? NSImage.lockLockedTemplateName : NSImage.lockUnlockedTemplateName

        let attachment = NSTextAttachment()
        attachment.image = NSImage(named: imageName)

        let attributed = NSMutableAttributedString(attachment: attachment)
        attributed.addAttribute(.baselineOffset, value: -1, range: NSRange(location: 0, length: attributed.length))

        return attributed
    }

    private func setUpStatusItem() {
        guard
            let statusBarButton = statusItem.button
        else { return }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApp.terminate), keyEquivalent: "q"))
        statusItem.menu = menu

        statusBarButton.rx.leftClickGesture()
            .when(.recognized)
            .toVoid()
            .filter { [popover] in
                !popover.isShown
            }
            .bind { [popover] in
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

    private func setUpPopover() {

        popover.contentViewController = self

        popover.rx.observe(\.isShown)
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: popover.rx.animates)
            .disposed(by: disposeBag)

        settingsViewController.rx.sentMessage(#selector(NSViewController.viewWillAppear))
            .toVoid()
            .map { .applicationDefined }
            .bind(to: popover.rx.behavior)
            .disposed(by: disposeBag)

        settingsViewController.rx.sentMessage(#selector(NSViewController.viewDidDisappear))
            .withLatestFrom(pinBtn.rx.state)
            .matching(.off)
            .toVoid()
            .startWith(())
            .map { .transient }
            .bind(to: popover.rx.behavior)
            .disposed(by: disposeBag)

        pinBtn.rx.state
            .map { $0 == .on ? .applicationDefined : .transient }
            .bind(to: popover.rx.behavior)
            .disposed(by: disposeBag)
    }

    private func styleButton(_ button: NSButton) {
        button.size(equalTo: 22)
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.refusesFirstResponder = true
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

        let keyLeft = keySubject.matching(123).toVoid()
        let keyRight = keySubject.matching(124).toVoid()
        let keyDown = keySubject.matching(125).toVoid()
        let keyUp = keySubject.matching(126).toVoid()


        let dateSelector = DateSelector(
            calendar: .autoupdatingCurrent,
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
