//
//  CalendarPickerViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import Cocoa
import RxSwift

class CalendarPickerViewController: NSViewController, NSPopoverDelegate {

    private let disposeBag = DisposeBag()

    private let viewModel: CalendarPickerViewModel

    private let contentStackView = NSStackView(.vertical)

    init(viewModel: CalendarPickerViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(
            viewModel.isPopover
                ? Accessibility.CalendarPicker.view
                : Accessibility.Settings.Calendars.view
        )
    }

    override func loadView() {

        view = NSView()

        let scrollView = NSScrollView()

        view.addSubview(scrollView)

        let insets: NSEdgeInsets = viewModel.isPopover ? .init(top: 16, left: 16, bottom: 16, right: 20) : .init()

        scrollView.edges(to: view, insets: insets)

        scrollView.drawsBackground = false
        scrollView.documentView = contentStackView.forAutoLayout()

        scrollView.contentView.edges(to: scrollView)
        scrollView.contentView.top(equalTo: contentStackView)
        scrollView.contentView.leading(equalTo: contentStackView)
        scrollView.contentView.trailing(equalTo: contentStackView)
        scrollView.contentView.height(equalTo: contentStackView).priority = .dragThatCanResizeWindow
        scrollView.contentView.heightAnchor.constraint(
            lessThanOrEqualToConstant: viewModel.isPopover ? 0.8 * NSScreen.main!.visibleFrame.height : 600
        ).activate()

        contentStackView.alignment = .left
    }

    private func setUpBindings() {

        if let popoverSettings = viewModel.popoverSettings {

            let popoverView = view.rx.observe(\.superview)
                .compactMap { $0 as? NSVisualEffectView }
                .take(1)

            Observable.combineLatest(
                popoverView, popoverSettings.popoverMaterial
            )
            .bind { $0.material = $1 }
            .disposed(by: disposeBag)
        }

        viewModel.calendars
            .observe(on: MainScheduler.instance)
            .compactMap { [weak self] calendars -> [NSView]? in
                guard let self = self else { return nil }

                return Dictionary(grouping: calendars, by: { $0.account })
                    .sorted(by: \.key.localizedLowercase)
                    .flatMap { account, calendars in
                        self.makeCalendarSection(
                            title: account,
                            calendars: calendars.sorted(by: \.title.localizedLowercase)
                        )
                    }
            }
            .bind(to: contentStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }
    
    private func makeCalendarSection(title: String, calendars: [CalendarModel]) -> [NSView] {

        let label = Label(text: title, font: .systemFont(ofSize: 11, weight: .semibold))
        label.textColor = .secondaryLabelColor

        let stackView = NSStackView(
            views: calendars.compactMap(makeCalendarItem)
        )
        .with(orientation: .vertical)
        .with(alignment: .left)

        return [label, NSStackView(views: [.dummy, stackView])]
    }

    private func makeCalendarItem(_ calendar: CalendarModel) -> NSView {

        let checkbox = Checkbox(title: calendar.title)
        checkbox.setTitleColor(color: calendar.color)

        viewModel.enabledCalendars
            .map { $0.contains(calendar.identifier) ? .on : .off }
            .bind(to: checkbox.rx.state)
            .disposed(by: disposeBag)

        checkbox.rx.tap
            .map { calendar.identifier }
            .bind(to: viewModel.toggleCalendar)
            .disposed(by: disposeBag)

        return checkbox
    }

    func popoverDidShow(_ notification: Notification) {
        // 🔨 Allow dismiss with the escape key
        view.window?.makeKey()
        view.window?.makeFirstResponder(self)
    }

    private var popover: NSPopover?

    func popoverWillClose(_ notification: Notification) {
        // 🔨 Prevent retain cycle
        view.window?.makeFirstResponder(nil)
    }

    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        self.popover = popover
        return true
    }

    func popoverDidClose(_ notification: Notification) {
        // 🔨 Prevent retain cycle
        popover?.contentViewController = nil
        popover = nil
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
