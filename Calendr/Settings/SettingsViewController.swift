//
//  SettingsViewController.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import RxSwift
import RxCocoa

class SettingsViewController: NSTabViewController {

    private let disposeBag = DisposeBag()

    init(settingsViewModel: SettingsViewModel, calendarsViewModel: CalendarPickerViewModel) {

        super.init(nibName: nil, bundle: nil)

        title = ""

        tabStyle = .toolbar

        let generalSettingsViewController = GeneralSettingsViewController(viewModel: settingsViewModel)
        let calendarPickerViewController = CalendarPickerViewController(viewModel: calendarsViewModel)

        let general = NSTabViewItem(viewController: generalSettingsViewController)
        let calendar = NSTabViewItem(viewController: calendarPickerViewController)

        general.label = "General"
        general.image = NSImage(named: NSImage.homeTemplateName)

        calendar.label = "Calendars"
        calendar.image = NSImage(named: NSImage.iconViewTemplateName)

        tabViewItems = [general, calendar]

        setUpBindings()
    }

    private func setUpBindings() {

        for (i, vc) in tabViewItems.compactMap(\.viewController).enumerated() {

            vc.rx.sentMessage(#selector(viewDidLayout))
                .withLatestFrom(rx.observe(\.selectedTabViewItemIndex))
                .matching(i)
                .toVoid()
                .map { vc.view.fittingSize }
                .distinctUntilChanged()
                .skip(i > 0 ? 1 : 0)
                .map(sizeWithPadding)
                .bind(to: rx.preferredContentSize)
                .disposed(by: disposeBag)
        }
    }

    override func loadView() {

        super.loadView()

        let contentView = view

        view.removeFromSuperview()

        view = NSView()

        view.addSubview(contentView)

        contentView.edges(to: view, constant: Constants.contentPadding)
    }

    override func viewDidAppear() {

        view.window?.styleMask.remove(.resizable)

        NSApp.activate(ignoringOtherApps: true)
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func sizeWithPadding(_ size: NSSize) -> NSSize {
    NSSize(
        width: size.width + 2 * Constants.contentPadding,
        height: size.height + 2 * Constants.contentPadding
    )
}

private enum Constants {

    static let contentPadding: CGFloat = 24
}
