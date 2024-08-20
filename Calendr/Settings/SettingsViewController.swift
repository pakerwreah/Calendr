//
//  SettingsViewController.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Cocoa
import RxSwift

enum SettingsTab: Int {
    case general
    case calendars
    case keyboard
    case about
}

class SettingsViewController: NSTabViewController {

    private let notificationCenter: NotificationCenter
    private let disposeBag = DisposeBag()
    private let keyboard = Keyboard()

    init(
        settingsViewModel: SettingsViewModel,
        calendarsViewModel: CalendarPickerViewModel,
        notificationCenter: NotificationCenter,
        autoUpdater: AutoUpdater
    ) {

        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)

        title = ""

        tabStyle = .toolbar

        let general = NSTabViewItem(viewController: GeneralSettingsViewController(viewModel: settingsViewModel))
        let calendars = NSTabViewItem(
            viewController: CalendarPickerViewController(viewModel: calendarsViewModel, configuration: .settings)
        )
        let keyboard = NSTabViewItem(viewController: KeyboardViewController())
        let about = NSTabViewItem(viewController: AboutViewController(autoUpdater: autoUpdater))

        general.label = Strings.Settings.Tab.general
        general.image = Icons.Settings.general

        calendars.label = Strings.Settings.Tab.calendars
        calendars.image = Icons.Settings.calendars

        keyboard.label = Strings.Settings.Tab.keyboard
        keyboard.image = Icons.Settings.keyboard

        about.label = Strings.Settings.Tab.about
        about.image = Icons.Settings.about

        tabViewItems = [general, calendars, keyboard, about]

        setUpAccessibility()

        setUpBindings()

        setUpKeyboard()
    }

    deinit {
        tearDownAccessibility()
    }

    override func loadView() {

        super.loadView()

        let contentView = view

        view.removeFromSuperview()

        view = NSView().forAutoLayout()

        view.addSubview(contentView)

        contentView.edges(to: view, constant: Constants.padding)
    }

    override func viewDidAppear() {

        super.viewDidAppear()

        setUpAccessibilityWindow()

        view.window?.styleMask.remove(.resizable)

        NSApp.activate(ignoringOtherApps: true)
    }

    override func viewDidDisappear() {

        super.viewDidDisappear()

        tearDownAccessibilityWindow()
    }

    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {

        super.tabView(tabView, willSelect: tabViewItem)

        view.window?.makeFirstResponder(nil)
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {

        super.tabView(tabView, didSelect: tabViewItem)

        guard let itemView = tabViewItem?.view, let window = view.window else { return }

        itemView.isHidden = true

        DispatchQueue.main.async {

            self.preferredContentSize = sizeWithPadding(itemView.fittingSize)

            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.1
                context.allowsImplicitAnimation = true
                window.layoutIfNeeded()
            }) {
                itemView.animator().isHidden = false
            }
        }
    }

    private func setUpBindings() {
        /**
         * Fix `Collision between RxCocoa interception mechanism and KVO`
         * which crashes the app if we call bind on `methodInvoked` after `rx.observe`
         *
         * To reproduce:
         *  1. open this view controller via the menu bar context menu
         *  2. click the menu bar to open the calendar popover
         */
        rx.viewDidLoad.subscribe().dispose()

        for (i, vc) in tabViewItems.compactMap(\.viewController).enumerated() {

            Observable.merge(
                notificationCenter.rx.notification(NSLocale.currentLocaleDidChangeNotification).void(),
                vc.rx.viewDidLayout
            )
            .withLatestFrom(rx.observe(\.selectedTabViewItemIndex))
            .matching(i)
            .void()
            .map { vc.view.fittingSize }
            .distinctUntilChanged()
            .skip(i > 0 ? 1 : 0)
            .map(sizeWithPadding)
            .bind(to: rx.preferredContentSize)
            .disposed(by: disposeBag)
        }
    }

    private func setUpKeyboard() {

        keyboard.listen(in: self) { [weak self] event, key -> NSEvent? in
            guard let self else { return event }

            switch key {
            case .escape:
                view.window?.performClose(nil)
            default:
                return event
            }

            return .none
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func sizeWithPadding(_ size: NSSize) -> NSSize {
    NSSize(
        width: max(size.width, Constants.minWidth) + 2 * Constants.padding,
        height: size.height + 2 * Constants.padding
    )
}

private enum Constants {

    static let padding: CGFloat = 24
    static let minWidth: CGFloat = 250
}

// MARK: - Accessibility

extension SettingsViewController {

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        NSApp.addAccessibilityChild(view)

        view.setAccessibilityIdentifier(Accessibility.Settings.view)
    }

    private func tearDownAccessibility() {

        guard BuildConfig.isUITesting else { return }

        NSApp.removeAccessibilityChild(view)
    }

    private func setUpAccessibilityWindow() {

        guard BuildConfig.isUITesting, let window = view.window else { return }

        window.setAccessibilityIdentifier(Accessibility.Settings.window)

        NSApp.addAccessibilityChild(window)
    }

    private func tearDownAccessibilityWindow() {

        guard BuildConfig.isUITesting, let window = view.window else { return }

        NSApp.removeAccessibilityChild(window)
    }
}
