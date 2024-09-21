//
//  EventDetailsViewController.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Cocoa
import MapKit
import WeatherKit
import RxSwift

class EventDetailsViewController: NSViewController, PopoverDelegate, MKMapViewDelegate {

    private let disposeBag = DisposeBag()

    private let scrollView = NSScrollView()
    private let eventTypeIcon = NSImageView()
    private let contentStackView = NSStackView(.vertical)
    private let participantsStackView = NSStackView(.vertical)
    private let detailsStackView = NSStackView(.vertical)
    private let footerStackView = NSStackView(.horizontal)
    private let linkBtn = ImageButton()

    private let titleLabel = Label()
    private let urlLabel = Label()
    private let locationLabel = Label()
    private let durationLabel = Label()
    private let notesTextView = NSTextView()

    private let skipButton = NSButton()

    private let optionsLabel = Label()
    private let optionsButton = NSButton()

    private var hasFooter = false

    private let viewModel: EventDetailsViewModel
    
    private lazy var notesHeightConstraint = notesTextView.height(equalTo: 0)

    init(viewModel: EventDetailsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        NSApp.addAccessibilityChild(view)

        view.setAccessibilityIdentifier(viewModel.accessibilityIdentifier)
    }

    deinit {
        guard BuildConfig.isUITesting else { return }
        
        NSApp.removeAccessibilityChild(view)
    }

    override func loadView() {

        view = NSView()

        view.width(lessThanOrEqualTo: 400 * Scaling.current)
        view.width(greaterThanOrEqualTo: 250 * Scaling.current)
        view.width(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.5, priority: .dragThatCanResizeWindow)

        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.documentView = detailsStackView.forAutoLayout()
        detailsStackView.edgeInsets = .init(horizontal: 12)
        detailsStackView.setHuggingPriority(.required, for: .horizontal)

        scrollView.contentView.edges(equalTo: scrollView)
        scrollView.contentView.top(equalTo: detailsStackView)
        scrollView.contentView.leading(equalTo: detailsStackView)
        scrollView.contentView.trailing(equalTo: detailsStackView)
        scrollView.contentView.height(equalTo: detailsStackView, priority: .dragThatCanResizeWindow)
        scrollView.contentView.height(lessThanOrEqualTo: 0.8 * NSScreen.main!.visibleFrame.height)

        contentStackView.addArrangedSubview(scrollView)
        contentStackView.spacing = 16
        contentStackView.setHuggingPriority(.required, for: .vertical)

        detailsStackView.setHuggingPriority(.required, for: .vertical)

        view.addSubview(contentStackView)

        contentStackView.edges(equalTo: view, margins: .init(vertical: 12))

        setUpIcon()
        setUpLink()
        setUpSkip()
        setUpOptions()
        setUpLabels()

        addInformation()
        addParticipants()
        addNotes()
        addFooter()
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
            eventTypeIcon.image = Icons.Event.reminder.with(pointSize: 12)
            eventTypeIcon.contentTintColor = .headerTextColor
        }

        eventTypeIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setUpLink() {

        guard let link = viewModel.link else {
            linkBtn.isHidden = true
            return
        }

        viewModel.isInProgress
            .observe(on: MainScheduler.instance)
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
            .bind(to: viewModel.linkTapped)
            .disposed(by: disposeBag)
    }

    private func setUpSkip() {
        guard viewModel.showSkip else { return }

        addSkipButton()

        skipButton.rx.tap
            .bind(to: viewModel.skipTapped)
            .disposed(by: disposeBag)
    }

    private func setUpOptions() {

        guard let contextMenuViewModel = viewModel.makeContextMenuViewModel() else { return }

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
            addReminderOptionsButton()

        default:
            return assertionFailure("That's weird, we should not have a view model in this case.")
        }

        createOptionsMenu(contextMenuViewModel)
    }

    private func createOptionsMenu(_ viewModel: some ContextMenuViewModel) {

        let menu = ContextMenu(viewModel: viewModel)

        optionsButton.rx.tap.bind { [optionsButton] in
            menu.popUp(
                positioning: nil,
                at: NSPoint(x: 0, y: optionsButton.bounds.height),
                in: optionsButton
            )
        }
        .disposed(by: disposeBag)
    }

    private func setButtonStyle(_ button: NSButton) {
        button.bezelStyle = .accessoryBar
        button.contentTintColor = .labelColor
        button.refusesFirstResponder = true
        button.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private func addSkipButton() {
        hasFooter = true

        skipButton.title = Strings.EventAction.skip
        skipButton.image = Icons.Event.skip.with(scale: .small)
        skipButton.imagePosition = .imageTrailing

        setButtonStyle(skipButton)

        footerStackView.addArrangedSubview(skipButton)
        footerStackView.addArrangedSubview(.spacer)
    }

    private func addReminderOptionsButton() {
        hasFooter = true

        optionsButton.title = Strings.Reminder.Options.button
        optionsButton.image = Icons.EventDetails.optionsArrow.with(scale: .small)
        optionsButton.imagePosition = .imageTrailing

        setButtonStyle(optionsButton)

        footerStackView.addArrangedSubview(.spacer)
        footerStackView.addArrangedSubview(optionsButton)
    }

    private func addEventStatusButton(icon: NSImage, color: NSColor, title: String) {
        hasFooter = true

        optionsLabel.stringValue = Strings.EventStatus.label
        optionsLabel.textColor = .secondaryLabelColor
        optionsLabel.setContentHuggingPriority(.required, for: .vertical)
        optionsLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        optionsButton.image = icon.with(color: color)
        optionsButton.title = title
        optionsButton.imagePosition = .imageLeading

        setButtonStyle(optionsButton)

        optionsButton.showsBorderOnlyWhileMouseInside = true

        footerStackView.addArrangedSubview(.spacer)
        footerStackView.addArrangedSubview(optionsLabel)
        footerStackView.addArrangedSubview(optionsButton)
    }

    private func addFooter() {
        guard hasFooter else { return }

        footerStackView.alignment = .centerY
        footerStackView.edgeInsets = .init(horizontal: 12)
        footerStackView.setHuggingPriority(.defaultHigh, for: .vertical)

        contentStackView.addArrangedSubview(footerStackView)
    }

    private func setUpLabels() {

        for label in  [titleLabel, urlLabel, locationLabel, durationLabel] {
            label.textColor = .labelColor
            label.lineBreakMode = .byWordWrapping
            label.isSelectable = true
            label.setContentHuggingPriority(.required, for: .vertical)
            label.setContentCompressionResistancePriority(.required, for: .vertical)
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

    private func addInformation() {

        let titleStack = NSStackView(views: [titleLabel, eventTypeIcon, linkBtn]).with(alignment: .firstBaseline)
        titleStack.setHuggingPriority(.required, for: .vertical)

        if !viewModel.title.isEmpty {
            titleLabel.stringValue = viewModel.title
            detailsStackView.addArrangedSubview(titleStack)
        }

        if !viewModel.url.isEmpty {
            urlLabel.stringValue = viewModel.url
            detailsStackView.addArrangedSubview(makeLine())
            detailsStackView.addArrangedSubview(urlLabel)
        }

        if !viewModel.location.isEmpty {
            locationLabel.stringValue = viewModel.location
            detailsStackView.addArrangedSubview(makeLine())

            if viewModel.canShowMap.value {
                let weatherContainer = NSView().with(size: CGSize(width: 30, height: 26))

                let locationStack = NSStackView(.horizontal).with(alignment: .centerY)
                locationStack.setHuggingPriority(.defaultHigh, for: .vertical)
                locationStack.addArrangedSubview(locationLabel)
                locationStack.addArrangedSubview(weatherContainer)

                detailsStackView.addArrangedSubview(locationStack)

                let mapIndex = detailsStackView.arrangedSubviews.count
                addLocationMap(at: mapIndex)
                addLocationWeather(in: weatherContainer)
            } else {
                detailsStackView.addArrangedSubview(locationLabel)
            }
        }

        if !viewModel.duration.isEmpty {
            durationLabel.stringValue = viewModel.duration
            detailsStackView.addArrangedSubview(makeLine())
            detailsStackView.addArrangedSubview(durationLabel)
        }
    }

    private enum Map {
        static let corner: CGFloat = 6
        static let height: CGFloat = 150
        static let distance: CLLocationDistance = 1000
        
        static func region(for center: Coordinates) -> MKCoordinateRegion {
            .init(center: .init(center), latitudinalMeters: distance, longitudinalMeters: distance)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let pin = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        pin.animatesWhenAdded = true
        return pin
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        mapView.deselectAnnotation(annotation, animated: false)
        mapView.setCenter(annotation.coordinate, animated: true)
    }

    private var isMapVisible = false

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        guard !isMapVisible else { return }
        isMapVisible = true

        mapView.animator().alphaValue = 1
        mapView.isScrollEnabled = true

        let annotation = MKPointAnnotation()
        annotation.coordinate = mapView.region.center
        mapView.addAnnotation(annotation)
    }

    private func addLocationMap(at index: Int) {

        viewModel.coordinates
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] coordinates in
                guard let self else { return }

                let mapView = MKMapView()
                mapView.delegate = self
                mapView.height(equalTo: Map.height)
                mapView.layer?.cornerRadius = Map.corner
                mapView.region = Map.region(for: coordinates)
                mapView.alphaValue = 0.01
                mapView.isScrollEnabled = false

                detailsStackView.insertArrangedSubview(mapView, at: index)

                addMapButton(in: mapView, for: coordinates)
            })
            .disposed(by: disposeBag)
    }

    func addMapButton(in mapView: MKMapView, for coordinates: Coordinates) {

        let mapButton = ImageButton(image: Icons.EventDetails.map)
        mapView.addSubview(mapButton)
        
        mapButton.size(equalTo: 26)
        mapButton.bottom(equalTo: mapView, constant: -2)
        mapButton.trailing(equalTo: mapView, constant: -2)

        mapButton.rx.tap
            .map(coordinates)
            .bind(to: viewModel.openMaps)
            .disposed(by: disposeBag)
    }

    private func addLocationWeather(in weatherContainer: NSView) {

        viewModel.weather
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak weatherContainer] weather, isAllDay in
                guard let weatherContainer, let firstHour = weather.hours.first else { return }

                let temperatures = isAllDay ? [weather.day.lowTemperature, weather.day.highTemperature] : [firstHour.temperature]
                let symbolName = isAllDay ? weather.day.symbolName : firstHour.symbolName

                guard let icon = NSImage.preferringMulticolor(systemName: symbolName) else { return }

                let temps = temperatures.map {
                    $0.formatted(
                        .measurement(usage: .weather, hidesScaleName: true, numberFormatStyle: .number.precision(.fractionLength(0)))
                    )
                }

                let weatherStack = NSStackView(.vertical).with(spacing: 6)
                weatherStack.addArrangedSubview(NSImageView(image: icon))
                weatherStack.addArrangedSubview(Label(text: temps.joined(separator: " "), font: .systemFont(ofSize: temps.count > 1 ? 10 : 12), align: .center))

                weatherContainer.addSubview(weatherStack)
                weatherStack.center(in: weatherContainer)
            })
            .disposed(by: disposeBag)
    }

    private func addNotes() {

        guard !viewModel.notes.isEmpty else { return }
        let notes = viewModel.notes

        if ["<", ">"].allSatisfy(notes.contains), let html = notes.html(font: .scaled(.default), color: .labelColor) {
            notesTextView.textStorage?.setAttributedString(html)
        } else {
            notesTextView.font = .scaled(.default)
            notesTextView.string = notes
        }
        notesTextView.checkTextInDocument(nil)
        notesTextView.isEditable = false

        detailsStackView.addArrangedSubview(makeLine())
        detailsStackView.addArrangedSubview(notesTextView)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        notesHeightConstraint.constant = notesTextView.contentSize.height
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
            stack.setHuggingPriority(.required, for: .vertical)
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
        scrollView.contentView.edges(equalTo: scrollView)
        scrollView.contentView.width(equalTo: participantsStackView, constant: 20)
        scrollView.contentView.height(equalTo: participantsStackView, priority: .defaultHigh)
        scrollView.contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 222).activate()

        participantsStackView.setHuggingPriority(.required, for: .vertical)
        participantsStackView.layoutSubtreeIfNeeded()
        participantsStackView.scrollTop()
    }

    private func setUpBindings() {

        let popoverView = view.rx.observe(\.superview)
            .compactMap { $0 as? NSVisualEffectView }
            .take(1)

        Observable.combineLatest(
            popoverView, viewModel.settings.popoverMaterial
        )
        .bind { $0.material = $1 }
        .disposed(by: disposeBag)

        viewModel.close
            .observe(on: MainScheduler.instance)
            .subscribe(
                onCompleted: { [weak self] in
                    self?.view.window?.performClose(nil)
                },
                onError: { error in
                    NSAlert(error: error).runModal()
                }
            )
            .disposed(by: disposeBag)
    }

    func popoverDidShow() {

        viewModel.isShowingObserver.onNext(true)
    }

    func popoverDidClose() {

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

    static func scaled(_ font: NSFont) -> NSFont {
        font.withSize(font.pointSize * Scaling.current)
    }
}
