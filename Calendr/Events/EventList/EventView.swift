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

    private let icon = NSImageView()
    private let title = Label()
    private let subtitle = Label()
    private let subtitleLink = Label()
    private let duration = Label()
    private let progress = NSView()
    private let linkBtn = ImageButton()
    private let hoverLayer = CALayer()
    private let colorBar = NSView()

    private lazy var progressTop = progress.top(equalTo: self)

    init(viewModel: EventViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setUpBindings()

        setData()
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
            icon.image = Icons.Event.birthday.with(scale: .small)
            icon.contentTintColor = .systemRed

        case .reminder:
            icon.image = Icons.Event.reminder.with(scale: .small).with(pointSize: 9)
            icon.contentTintColor = .headerTextColor

        case .event(let status):
            if status ~= .pending {
                layer?.backgroundColor = Self.pendingBackground
            }
            icon.isHidden = true
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

        duration.stringValue = viewModel.duration
        duration.isHidden = duration.isEmpty

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

        icon.setContentHuggingPriority(.required, for: .horizontal)
        icon.setContentCompressionResistancePriority(.required, for: .horizontal)

        title.forceVibrancy = false
        title.lineBreakMode = .byWordWrapping
        title.textColor = .headerTextColor
        title.font = .systemFont(ofSize: 12)

        duration.lineBreakMode = .byWordWrapping
        duration.textColor = .secondaryLabelColor
        duration.font = .systemFont(ofSize: 11)

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

        linkBtn.width(equalTo: 22)

        let titleStackView = NSStackView(views: [icon, title]).with(spacing: 4).with(alignment: .firstBaseline)

        let linkStackView = NSStackView(views: [subtitleLink, linkBtn]).with(spacing: 0)

        linkStackView.rx.isContentHidden
            .bind(to: linkStackView.rx.isHidden)
            .disposed(by: disposeBag)

        let eventStackView = NSStackView(views: [titleStackView, subtitle, linkStackView, duration])
            .with(orientation: .vertical)
            .with(spacing: 2)
            .with(insets: .init(vertical: 1))

        let contentStackView = NSStackView(views: [colorBar, eventStackView])
        addSubview(contentStackView)
        contentStackView.edges(equalTo: self)

        addSubview(progress, positioned: .below, relativeTo: nil)

        progress.isHidden = true
        progress.wantsLayer = true
        progress.layer?.backgroundColor = NSColor.red.cgColor.copy(alpha: 0.7)
        progress.height(equalTo: 1)
        progress.width(equalTo: self)
    }

    private func setUpBindings() {

        rx.isHovered
            .map(!)
            .bind(to: hoverLayer.rx.isHidden)
            .disposed(by: disposeBag)

        if let link = viewModel.link {
            (
                link.isMeeting
                    ? viewModel.isInProgress.map { $0 ? Icons.Event.video_fill : Icons.Event.video }
                    : .just(Icons.Event.link)
            )
            .map { $0.with(scale: .small) }
            .bind(to: linkBtn.rx.image)
            .disposed(by: disposeBag)

            viewModel.isInProgress.map { $0 ? .controlAccentColor : .secondaryLabelColor }
                .bind(to: linkBtn.rx.contentTintColor)
                .disposed(by: disposeBag)

            linkBtn.rx.tap
                .bind { [viewModel] in viewModel.workspace.open(link.url) }
                .disposed(by: disposeBag)
        }

        if viewModel.type.isEvent || viewModel.type.isReminder {

            viewModel.isFaded
                .map { $0 ? 0.5 : 1 }
                .bind(to: rx.alpha)
                .disposed(by: disposeBag)

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

    private static let pendingBackground: CGColor = {

        let stripes = CIFilter.stripesGenerator()
        stripes.color0 = CIColor(color: NSColor.gray.withAlphaComponent(0.25))!
        stripes.color1 = .clear
        stripes.width = 2.5
        stripes.sharpness = 0

        let rotated = CIFilter.affineClamp()
        rotated.inputImage = stripes.outputImage!
        rotated.transform = CGAffineTransform(rotationAngle: -.pi / 4)

        let ciImage = rotated.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        return NSColor(patternImage: nsImage).cgColor
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
