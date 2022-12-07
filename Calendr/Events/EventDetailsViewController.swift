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
    private let eventTypeIcon = NSImageView()
    private let contentStackView = NSStackView(.vertical)
    private let participantsStackView = NSStackView(.vertical)
    private let detailsStackView = NSStackView(.vertical)
    private let linkBtn = ImageButton()

    private let titleLabel = Label()
    private let urlLabel = Label()
    private let locationLabel = Label()
    private let durationLabel = Label()
    private let notesTextView = NSTextView()

    private let optionsLabel = Label()
    private let optionsButton = NSButton()
    private lazy var eventOptions = EventOptions(current: viewModel.status)
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

        contentStackView.addArrangedSubview(scrollView)

        view.addSubview(contentStackView)

        contentStackView.edges(to: view, constant: 12)

        setUpIcon()
        setUpLinkButton()
        setUpLabels()
        setUpOptions()

        addInformation()
        addParticipants()
        addNotes()
    }

    private func setUpLabels() {

        for label in  [titleLabel, urlLabel, locationLabel, durationLabel] {
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

        notesTextView.textColor = .labelColor
        notesTextView.isSelectable = true
        notesTextView.drawsBackground = false
        notesTextView.isAutomaticLinkDetectionEnabled = true
        notesTextView.textContainer?.lineFragmentPadding = .zero
    }

    private func setUpOptions() {

        switch viewModel.type {

        case .event(.accepted):
            addEventStatusButton(icon: Icons.EventStatus.accepted, color: .systemGreen, title: Strings.EventStatus.accepted)

        case .event(.maybe):
            addEventStatusButton(icon: Icons.EventStatus.maybe, color: .systemOrange, title: Strings.EventStatus.maybe)

        case .event(.pending):
            addEventStatusButton(icon: Icons.EventStatus.pending, color: .systemGray, title: Strings.EventStatus.pending)

        case .event(.declined):
            addEventStatusButton(icon: Icons.EventStatus.declined, color: .systemRed, title: Strings.EventStatus.declined)

        case .reminder:
            optionsButton.title = Strings.Reminder.Options.button
            optionsButton.image = Icons.EventDetails.optionsArrow.with(scale: .small)
            optionsButton.bezelStyle = .texturedRounded
            optionsButton.imagePosition = .imageTrailing
            addOptionsButton()

        default:
            break
        }
    }

    private func addEventStatusButton(icon: NSImage, color: NSColor, title: String) {

        optionsLabel.stringValue = Strings.EventStatus.label
        optionsLabel.textColor = .secondaryLabelColor
        optionsButton.image = icon.with(color: color)
        optionsButton.title = title
        optionsButton.imagePosition = .imageLeading
        addOptionsButton()
    }

    private func addOptionsButton() {

        optionsButton.bezelStyle = .texturedRounded
        optionsButton.setTitleColor(color: .labelColor)
        optionsButton.refusesFirstResponder = true
        optionsButton.setContentCompressionResistancePriority(.required, for: .vertical)
        let optionsStackView = NSStackView(views: [.spacer, optionsLabel, optionsButton]).with(alignment: .centerY)
        optionsStackView.setHuggingPriority(.defaultHigh, for: .vertical)
        optionsStackView.edgeInsets.top = 4
        contentStackView.addArrangedSubview(optionsStackView)
    }

    private func setUpIcon() {

        switch viewModel.type {
        case .event:
            eventTypeIcon.isHidden = true
            return

        case .birthday:
            eventTypeIcon.image = Icons.Event.birthday
            eventTypeIcon.contentTintColor = .systemRed

        case .reminder:
            eventTypeIcon.image = Icons.Event.reminder.with(size: 12)
            eventTypeIcon.contentTintColor = .headerTextColor
        }

        eventTypeIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setUpLinkButton() {

        guard let link = viewModel.link else {
            linkBtn.isHidden = true
            return
        }

        viewModel.isInProgress
            .bind { [linkBtn] isInProgress in
                if link.isMeeting {
                    linkBtn.image = isInProgress ? Icons.Event.video_fill : Icons.Event.video
                } else {
                    linkBtn.image = Icons.Event.link
                }
                linkBtn.contentTintColor = isInProgress ? .controlAccentColor : .secondaryLabelColor
            }
            .disposed(by: disposeBag)

        linkBtn.rx.tap
            .bind { [viewModel] in viewModel.workspace.open(link.url) }
            .disposed(by: disposeBag)
    }

    private func addInformation() {

        if !viewModel.title.isEmpty {
            titleLabel.stringValue = viewModel.title
            detailsStackView.addArrangedSubview(
                NSStackView(views: [titleLabel, eventTypeIcon, linkBtn]).with(alignment: .firstBaseline)
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
    }

    private func addNotes() {

        guard !viewModel.notes.isEmpty else { return }
        let notes = viewModel.notes

        if ["<", ">"].allSatisfy(notes.contains), let html = notes.html(font: .default, color: .labelColor) {
            notesTextView.textStorage?.setAttributedString(html)
        } else {
            notesTextView.font = .default
            notesTextView.string = notes
        }
        notesTextView.checkTextInDocument(nil)
        notesTextView.isEditable = false

        detailsStackView.addArrangedSubview(makeLine())
        detailsStackView.addArrangedSubview(notesTextView)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        notesTextView.height(equalTo: notesTextView.contentSize.height)
    }

    private func addParticipants() {

        guard !viewModel.participants.isEmpty else { return }

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
            label.isSelectable = true

            switch participant.status {
            case .accepted:
                status.image = Icons.EventStatus.accepted
                status.contentTintColor = .systemGreen

            case .maybe:
                status.image = Icons.EventStatus.maybe
                status.contentTintColor = .systemOrange

            case .declined:
                status.image = Icons.EventStatus.declined
                status.contentTintColor = .systemRed

            case .pending, .unknown:
                status.image = Icons.EventStatus.pending
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
        participantsStackView.scrollTop()
    }

    private func setUpBindings() {

        let popoverView = view.rx.observe(\.superview)
            .compactMap { $0 as? NSVisualEffectView }
            .take(1)

        Observable.combineLatest(
            popoverView, viewModel.popoverSettings.popoverMaterial
        )
        .bind { $0.material = $1 }
        .disposed(by: disposeBag)

        switch viewModel.type {
        case .event(let status) where status != .unknown:
            setUpOptionsMenuBindings(options: eventOptions, observer: viewModel.eventActionObserver)

        case .reminder:
            setUpOptionsMenuBindings(options: reminderOptions, observer: viewModel.reminderActionObserver)

        default:
            break
        }
    }

    private func setUpOptionsMenuBindings<T: NSMenu & ObservableConvertibleType>(
        options: T,
        observer: AnyObserver<T.Element>
    ) {

        optionsButton.rx.tap.bind { [optionsButton] in
            options.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: optionsButton.bounds.height),
                in: optionsButton
            )
        }
        .disposed(by: disposeBag)

        options.asObservable()
            .bind(to: observer)
            .disposed(by: disposeBag)

        viewModel.actionCallback
            .observe(on: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] in
                    self?.view.window?.performClose(nil)
                },
                onError: { error in
                    NSAlert(error: error).runModal()
                }
            )
            .disposed(by: disposeBag)
    }

    func popoverDidShow(_ notification: Notification) {
        // 🔨 Allow dismiss with the escape key
        view.window?.makeKey()
        view.window?.makeFirstResponder(self)

        // 🔨 Fix cursor not changing when hovering text
        NSApp.activate(ignoringOtherApps: true)

        viewModel.isShowingObserver.onNext(true)
    }

    func popoverWillShow(_ notification: Notification) {

        notification.popover.animates = false
    }

    func popoverWillClose(_ notification: Notification) {
        // 🔨 Prevent retain cycle
        view.window?.makeFirstResponder(nil)

        notification.popover.animates = true
    }

    func popoverDidClose(_ notification: Notification) {
        // 🔨 Prevent retain cycle
        notification.popover.contentViewController = nil

        viewModel.isShowingObserver.onNext(false)
    }

    private func makeLine() -> NSView {

        let line = NSView.spacer(height: 1)
        line.wantsLayer = true

        line.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.effectiveCGColor }
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

private extension Notification {

    var popover: NSPopover { object as! NSPopover  }
}
