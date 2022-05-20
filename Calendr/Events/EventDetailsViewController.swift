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
    private let statusIcon = NSImageView()
    private let participantsStackView = NSStackView(.vertical)
    private let detailsStackView = NSStackView(.vertical)

    private let titleLabel = Label()
    private let urlLabel = Label()
    private let locationLabel = Label()
    private let durationLabel = Label()
    private let notesLabel = Label()

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

        statusIcon.setContentCompressionResistancePriority(.required, for: .horizontal)

        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.documentView = detailsStackView.forAutoLayout()

        scrollView.contentView.edges(to: scrollView)
        scrollView.contentView.top(equalTo: detailsStackView)
        scrollView.contentView.leading(equalTo: detailsStackView)
        scrollView.contentView.trailing(equalTo: detailsStackView)
        scrollView.contentView.height(equalTo: detailsStackView).priority = .dragThatCanResizeWindow
        scrollView.contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 0.8 * NSScreen.main!.visibleFrame.height).activate()

        let contentStackView = NSStackView(views: [scrollView]).with(orientation: .vertical)

        view.addSubview(contentStackView)

        contentStackView.edges(to: view, constant: 12)

        for label in  [titleLabel, urlLabel, locationLabel, durationLabel, notesLabel] {
            label.textColor = .labelColor
            label.lineBreakMode = .byWordWrapping
            label.isSelectable = true
        }

        titleLabel.forceVibrancy = false
        titleLabel.textColor = .headerTextColor
        titleLabel.font = .header

        locationLabel.font = .small
        urlLabel.font = .small
        durationLabel.font = .default

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

        if !viewModel.title.isEmpty {
            titleLabel.stringValue = viewModel.title
            detailsStackView.addArrangedSubview(
                NSStackView(views: [titleLabel, statusIcon]).with(alignment: .firstBaseline)
            )
        }

        if !viewModel.url.isEmpty {
            urlLabel.stringValue = viewModel.url
            detailsStackView.addArrangedSubview(makeLine())
            detailsStackView.addArrangedSubview(urlLabel)
        }

        if !viewModel.location.isEmpty {
            locationLabel.stringValue = viewModel.location
            detailsStackView.addArrangedSubview(makeLine())
            detailsStackView.addArrangedSubview(locationLabel)
        }

        if !viewModel.duration.isEmpty {
            durationLabel.stringValue = viewModel.duration
            detailsStackView.addArrangedSubview(makeLine())
            detailsStackView.addArrangedSubview(durationLabel)
        }

        if !viewModel.participants.isEmpty {

            for participant in viewModel.participants {

                let status = NSImageView()

                var info: String = participant.name

                if participant.isOrganizer {
                    info += " (\(Strings.EventDetails.Participant.organizer))"
                }

                if participant.isCurrentUser {
                    info += " (\(Strings.EventDetails.Participant.me))"
                }

                let label = Label(text: info, font: .small)
                label.lineBreakMode = .byTruncatingMiddle

                switch participant.status {
                case .accepted:
                    status.image = Icons.EventDetails.Status.accepted
                    status.contentTintColor = .systemGreen

                case .maybe:
                    status.image = Icons.EventDetails.Status.maybe
                    status.contentTintColor = .systemOrange

                case .declined:
                    status.image = Icons.EventDetails.Status.declined
                    status.contentTintColor = .systemRed

                case .pending, .unknown:
                    status.image = Icons.EventDetails.Status.pending
                    status.contentTintColor = .systemGray
                }

                let stack = NSStackView(views: [status, label])
                label.setContentCompressionResistancePriority(.required, for: .vertical)

                participantsStackView.addArrangedSubview(stack)
            }

            let scrollView = NSScrollView()
            detailsStackView.addArrangedSubview(makeLine())
            detailsStackView.addArrangedSubview(scrollView)

            scrollView.hasVerticalScroller = true
            scrollView.scrollerStyle = .legacy
            scrollView.drawsBackground = false
            scrollView.documentView = participantsStackView.forAutoLayout()
            scrollView.contentView.edges(to: scrollView)
            scrollView.contentView.width(equalTo: participantsStackView, constant: 20)
            scrollView.contentView.height(equalTo: participantsStackView).priority = .defaultHigh
            scrollView.contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 222).activate()
            participantsStackView.layoutSubtreeIfNeeded()
            participantsStackView.scroll(.init(x: 0, y: participantsStackView.frame.height))
        }

        if !viewModel.notes.isEmpty {
            if ["<", ">"].allSatisfy(viewModel.notes.contains),
               let html = viewModel.notes.html(font: .default, color: .labelColor) {
                notesLabel.attributedStringValue = html
            } else {
                notesLabel.font = .default
                notesLabel.stringValue = viewModel.notes
            }
            detailsStackView.addArrangedSubview(makeLine())
            detailsStackView.addArrangedSubview(notesLabel)
        }

        switch viewModel.type {
        case .event:
            break

        case .birthday:
            statusIcon.image = Icons.Event.birthday
            statusIcon.contentTintColor = .systemRed

        case .reminder:
            statusIcon.image = Icons.Event.reminder.with(size: 12)
            statusIcon.contentTintColor = .headerTextColor
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

    func popoverDidShow(_ notification: Notification) {
        // 🔨 Allow dismiss with the escape key
        view.window?.makeKey()
        view.window?.makeFirstResponder(self)

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
