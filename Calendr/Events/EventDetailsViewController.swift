//
//  EventDetailsViewController.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Cocoa
import RxSwift

class EventDetailsViewController: NSViewController, NSPopoverDelegate {

    private let disposeBag = DisposeBag()

    private let scrollView = NSScrollView()

    private let _title = Label()
    private let url = Label()
    private let location = Label()
    private let duration = Label()
    private let notes = Label()

    private var fields: [Label] {
        [_title, url, location, duration, notes]
    }

    private lazy var optionsButton = NSButton()
    private lazy var reminderOptions = ReminderOptions()

    private let viewModel: EventDetailsViewModel

    init(viewModel: EventDetailsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        NSApp.addAccessibilityChild(view)

        view.setAccessibilityIdentifier(Accessibility.EventDetails.view)
    }

    deinit {
        guard BuildConfig.isUITesting else { return }
        
        NSApp.removeAccessibilityChild(view)
    }

    override func loadView() {

        view = NSView()

        view.widthAnchor.constraint(lessThanOrEqualToConstant: 400).activate()

        let detailsStackView = NSStackView(
            views: fields
                .enumerated()
                .map { index, field in
                    index > 0
                        ? NSStackView(views: [makeLine(), field]).with(orientation: .vertical)
                        : field
                }
        )
        .with(orientation: .vertical)

        detailsStackView.layoutSubtreeIfNeeded()

        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.documentView = detailsStackView

        scrollView.contentView.edges(to: scrollView)
        scrollView.contentView.top(equalTo: detailsStackView)
        scrollView.contentView.leading(equalTo: detailsStackView)
        scrollView.contentView.trailing(equalTo: detailsStackView)

        scrollView.height(equalTo: detailsStackView).priority = .defaultHigh
        scrollView.heightAnchor.constraint(lessThanOrEqualToConstant: 0.8 * NSScreen.main!.visibleFrame.height).activate()

        let contentStackView = NSStackView(views: [scrollView]).with(orientation: .vertical)

        view.addSubview(contentStackView)

        contentStackView.edges(to: view, constant: 12)

        for field in fields {
            field.textColor = .labelColor
            field.lineBreakMode = .byWordWrapping
            field.isSelectable = true
        }

        _title.forceVibrancy = false
        _title.textColor = .headerTextColor
        _title.font = .header

        location.font = .small
        url.font = .small
        duration.font = .default

        if viewModel.type.isReminder {
            optionsButton.title = Strings.Reminder.Options.button
            optionsButton.bezelStyle = .texturedRounded
            optionsButton.image = Icons.EventDetails.options.with(scale: .small)
            optionsButton.imagePosition = .imageTrailing

            let optionsStackView = NSStackView(views: [.spacer, optionsButton])
            optionsStackView.setHuggingPriority(.defaultHigh, for: .vertical)
            optionsStackView.edgeInsets.top = 4
            contentStackView.addArrangedSubview(optionsStackView)
        }
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        _title.stringValue = viewModel.title
        url.stringValue = viewModel.url
        location.stringValue = viewModel.location
        duration.stringValue = viewModel.duration

        if ["<", ">"].allSatisfy(viewModel.notes.contains),
           let html = viewModel.notes.html(font: .default, color: .labelColor) {
            notes.attributedStringValue = html
        } else {
            notes.font = .default
            notes.stringValue = viewModel.notes
        }

        for field in fields {
            field.superview?.isHidden = field.isEmpty
        }
    }

    private func setUpBindings() {

        let popoverView = view.rx.observe(\.superview)
            .compactMap { $0 as? NSVisualEffectView }
            .take(1)

        Observable.combineLatest(
            popoverView, viewModel.popoverMaterial
        )
        .bind { $0.material = $1 }
        .disposed(by: disposeBag)

        if viewModel.type.isReminder {

            optionsButton.rx.tap.bind { [optionsButton, reminderOptions] in
                reminderOptions.popUp(
                    positioning: nil,
                    at: NSPoint(x: 0, y: optionsButton.bounds.height),
                    in: optionsButton
                )
            }
            .disposed(by: disposeBag)

            reminderOptions.asObservable()
                .bind(to: viewModel.reminderActionObserver)
                .disposed(by: disposeBag)

            viewModel.reminderActionCallback
                .observe(on: MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] in
                        self?.view.window?.close()
                    },
                    onError: { error in
                        NSAlert(error: error).runModal()
                    }
                )
                .disposed(by: disposeBag)
        }
    }

    override func viewDidAppear() {

        super.viewDidAppear()

        view.window?.makeKey()
    }

    func popoverDidShow(_ notification: Notification) {

        scrollView.flashScrollers()
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

    private func makeLine() -> NSView {

        let line = NSView.spacer(height: 1)
        line.wantsLayer = true

        line.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.cgColor }
            .bind(to: line.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        return line
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


private extension NSFont {

    static let `default` = systemFont(ofSize: 13)
    static let header = systemFont(ofSize: 16)
    static let small = systemFont(ofSize: 12)
}
