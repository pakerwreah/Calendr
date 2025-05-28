//
//  EventView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import Cocoa
import RxSwift
import RxCocoa
import CoreImage.CIFilterBuiltins

class EventView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: EventViewModel

    private let birthdayIcon = NSImageView()
    private let recurrenceIcon = NSImageView()
    private let priority = Label()
    private let title = Label()
    private let subtitle = Label()
    private let subtitleLink = Label(align: .left)
    private let duration = Label()
    private let relativeDuration = Label()
    private let progress = NSView()
    private let linkBtn = ImageButton()
    private let completeBtn = ImageButton()
    private let hoverLayer = CALayer()
    private let colorBar = NSView()

    private lazy var progressTop = progress.top(equalTo: self)

    init(viewModel: EventViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setData()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.EventList.event)
    }

    private func setUpContextMenu(_ viewModel: some ContextMenuViewModel) {
        menu = ContextMenu(viewModel: viewModel)
    }

    private func setData() {

        if let contextMenuViewModel = viewModel.makeContextMenuViewModel() {
            setUpContextMenu(contextMenuViewModel)
        }

        switch viewModel.type {

            case .birthday:
                birthdayIcon.isHidden = false

            case .reminder:
                priority.textColor = viewModel.color
                priority.stringValue = viewModel.priority ?? ""
                priority.isHidden = viewModel.priority == nil

                completeBtn.contentTintColor = viewModel.color
                completeBtn.isHidden = false

            case .event:
                break
        }

        switch viewModel.barStyle {

            case .filled:
                colorBar.layer?.backgroundColor = viewModel.color.cgColor

            case .bordered:
                colorBar.layer?.borderWidth = 1
                colorBar.layer?.borderColor = viewModel.color.cgColor
        }

        title.attributedStringValue = .init(
            string: viewModel.title,
            attributes: viewModel.isDeclined ? [.strikethroughStyle: NSUnderlineStyle.single.rawValue] : [:]
        )

        subtitle.stringValue = viewModel.subtitle
        subtitle.isHidden = subtitle.isEmpty

        if let link = viewModel.subtitleLink {
            subtitleLink.stringValue = link
        } else {
            subtitleLink.isHidden = true
        }

        linkBtn.isHidden = viewModel.link == nil
        linkBtn.toolTip = viewModel.link?.url.absoluteString
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        layer?.cornerRadius = 2

        hoverLayer.isHidden = true
        hoverLayer.backgroundColor = NSColor.gray.cgColor.copy(alpha: 0.2)
        layer?.addSublayer(hoverLayer)

        [birthdayIcon, recurrenceIcon, completeBtn, priority, relativeDuration].forEach {
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }

        completeBtn.isHidden = true

        priority.isHidden = true
        priority.font = .systemFont(ofSize: 13)

        birthdayIcon.isHidden = true
        birthdayIcon.contentTintColor = .systemRed

        title.forceVibrancy = false
        title.lineBreakMode = .byWordWrapping
        title.textColor = .headerTextColor
        title.font = .systemFont(ofSize: 12)

        duration.lineBreakMode = .byWordWrapping
        duration.textColor = .secondaryLabelColor
        duration.font = .systemFont(ofSize: 11)

        relativeDuration.isHidden = true
        relativeDuration.textColor = .secondaryLabelColor
        relativeDuration.font = .systemFont(ofSize: 10)

        subtitle.lineBreakMode = .byWordWrapping
        subtitle.maximumNumberOfLines = 2
        subtitle.cell?.truncatesLastVisibleLine = true
        subtitle.textColor = .secondaryLabelColor
        subtitle.font = .systemFont(ofSize: 10)

        subtitleLink.lineBreakMode = .byTruncatingTail
        subtitleLink.textColor = .secondaryLabelColor
        subtitleLink.font = .systemFont(ofSize: 11)

        colorBar.wantsLayer = true
        colorBar.layer?.cornerRadius = 2
        colorBar.width(equalTo: 4)

        let titleStackView = NSStackView(views: [birthdayIcon, completeBtn, priority, title, recurrenceIcon])
            .with(spacing: 3)
            .with(alignment: .firstBaseline)

        let linkStackView = NSStackView(views: [subtitleLink, linkBtn]).with(spacing: 0)

        let durationStackView = NSStackView(views: [duration, relativeDuration])
        duration.setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        durationStackView.setHuggingPriority(.defaultHigh, for: .horizontal)

        linkStackView.rx.isContentHidden
            .bind(to: linkStackView.rx.isHidden)
            .disposed(by: disposeBag)

        durationStackView.rx.isContentHidden
            .bind(to: durationStackView.rx.isHidden)
            .disposed(by: disposeBag)

        let eventStackView = NSStackView(views: [titleStackView, subtitle, linkStackView, durationStackView])
            .with(orientation: .vertical)
            .with(spacing: 3)
            .with(insets: .init(vertical: 2))

        let contentStackView = NSStackView(views: [colorBar, .dummy, eventStackView, .dummy]).with(spacing: 4)
        addSubview(contentStackView)
        contentStackView.edges(equalTo: self)

        addSubview(progress, positioned: .below, relativeTo: nil)

        progress.isHidden = true
        progress.wantsLayer = true
        progress.layer?.backgroundColor = NSColor.red.cgColor.copy(alpha: 0.7)
        progress.height(equalTo: 1)
        progress.leading(equalTo: self)
        progress.trailing(equalTo: self)
    }

    private func setUpBindings() {

        rx.isHovered
            .map(!)
            .bind(to: hoverLayer.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.duration
            .bind(to: duration.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.duration.map(\.isEmpty)
            .bind(to: duration.rx.isHidden)
            .disposed(by: disposeBag)

        if let link = viewModel.link {
            Observable.combineLatest(
                link.isMeeting
                    ? viewModel.isInProgress.map { $0 ? Icons.Event.video_fill : Icons.Event.video }
                    : .just(Icons.Event.link),
                Scaling.observable
            )
            .map { $0.with(pointSize: 10 * $1) }
            .bind(to: linkBtn.rx.image)
            .disposed(by: disposeBag)

            viewModel.isInProgress.map { $0 ? .controlAccentColor : .secondaryLabelColor }
                .bind(to: linkBtn.rx.contentTintColor)
                .disposed(by: disposeBag)

            linkBtn.rx.tap
                .bind(to: viewModel.linkTapped)
                .disposed(by: disposeBag)
        }

        if viewModel.type.isBirthday {

            Scaling.observable
                .map { Icons.Event.birthday.with(pointSize: 10 * $0) }
                .bind(to: birthdayIcon.rx.image)
                .disposed(by: disposeBag)

        } else {

            viewModel.isFaded
                .map { $0 ? 0.5 : 1 }
                .bind(to: rx.alpha)
                .disposed(by: disposeBag)

            Observable.combineLatest(viewModel.showRecurrenceIndicator, Scaling.observable)
                .filter(\.0)
                .map { Icons.Event.recurrence.with(pointSize: 10 * $1) }
                .bind(to: recurrenceIcon.rx.image)
                .disposed(by: disposeBag)

            viewModel.showRecurrenceIndicator
                .map(!)
                .bind(to: recurrenceIcon.rx.isHidden)
                .disposed(by: disposeBag)
        }

        if viewModel.type.isEvent {

            Observable.combineLatest(
                viewModel.progress, rx.observe(\.frame)
            )
            .compactMap { progress, frame in
                progress.map { max(1, $0 * frame.height - 0.5) }
            }
            .bind(to: progressTop.rx.constant)
            .disposed(by: disposeBag)

            viewModel.isInProgress
                .map(!)
                .bind(to: progress.rx.isHidden)
                .disposed(by: disposeBag)
        }

        if viewModel.type.isReminder {
            Observable
                .combineLatest(viewModel.isCompleted, Scaling.observable)
                .map { completed, scaling in
                    let icon = completed ? Icons.Reminder.complete : Icons.Reminder.incomplete
                    return icon.with(pointSize: 12 * scaling)
                }
                .bind(to: completeBtn.rx.image)
                .disposed(by: disposeBag)

            viewModel.relativeDuration
                .bind(to: relativeDuration.rx.stringValue)
                .disposed(by: disposeBag)

            viewModel.relativeDuration.map(\.isEmpty)
                .bind(to: relativeDuration.rx.isHidden)
                .disposed(by: disposeBag)

            completeBtn.rx.tap
                .bind(to: viewModel.completeTapped)
                .disposed(by: disposeBag)
        }

        viewModel.backgroundColor
            .map(\.cgColor)
            .bind(to: layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        rx.click {
            // do not delay other click events
            $0.delaysPrimaryMouseButtonEvents = false
        }
        .withUnretained(self)
        .flatMapFirst { [viewModel] view, _ -> Observable<Void> in
            let vm = viewModel.makeDetailsViewModel()
            let vc = EventDetailsViewController(viewModel: vm)
            let popover = Popover()
            popover.behavior = .transient
            popover.contentViewController = vc
            popover.delegate = vc
            popover.push(from: view, after: vm.optimisticLoadTime)

            return popover.rx.deallocated
                // prevent reopening immediately after dismiss
                .delay(.milliseconds(300), scheduler: MainScheduler.instance)
        }
        .subscribe()
        .disposed(by: disposeBag)

        rx.observe(\.frame)
            .bind { [weak self] _ in self?.updateLayer() }
            .disposed(by: disposeBag)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func updateLayer() {
        super.updateLayer()
        hoverLayer.frame = bounds
    }

    override func updateTrackingAreas() {
        trackingAreas.forEach(removeTrackingArea(_:))
        addTrackingRect(bounds, owner: self, userData: nil, assumeInside: false)

        // 🔨 Fix unhover not detected when scrolling
        guard let mouseLocation = window?.mouseLocationOutsideOfEventStream,
              isMousePoint(convert(mouseLocation, from: nil), in: bounds)
        else {
            return hoverLayer.isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
