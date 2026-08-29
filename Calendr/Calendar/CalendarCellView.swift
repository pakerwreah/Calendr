//
//  CalendarCellView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class CalendarCellView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: Observable<CalendarCellViewModel>
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>
    private let doubleClickObserver: AnyObserver<Date>
    private let calendarScaling: Observable<Double>
    private let textScaling: Observable<Double>

    private let label: Label
    private let lunarLabel: Label
    private let eventsStackView = NSStackView()
    private let borderLayer = CALayer()
    private let restDayLayer = CALayer()
    private var contentStackView: NSStackView!
    private var contentTopConstraint: NSLayoutConstraint!
    private var contentCenterYConstraint: NSLayoutConstraint!

    init(
        viewModel: Observable<CalendarCellViewModel>,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>,
        doubleClickObserver: AnyObserver<Date>,
        calendarScaling: Observable<Double>,
        textScaling: Observable<Double>
    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver
        self.doubleClickObserver = doubleClickObserver
        self.calendarScaling = calendarScaling
        self.textScaling = textScaling

        label = Label(font: .systemFont(ofSize: Constants.fontSize), scaling: textScaling)
        lunarLabel = Label(font: .systemFont(ofSize: Constants.lunarFontSize), scaling: textScaling)

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        clipsToBounds = false
        restDayLayer.cornerRadius = Constants.cornerRadius
        layer!.addSublayer(restDayLayer)
        borderLayer.cornerRadius = Constants.cornerRadius
        layer!.addSublayer(borderLayer)

        label.alignment = .center
        label.textColor = .headerTextColor
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)

        lunarLabel.alignment = .center
        lunarLabel.textColor = .secondaryLabelColor
        lunarLabel.maximumNumberOfLines = 1
        lunarLabel.lineBreakMode = .byClipping
        lunarLabel.setContentHuggingPriority(.required, for: .vertical)
        lunarLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        let eventsContainer = NSView()
        eventsContainer.addSubview(eventsStackView)

        eventsStackView.spacing = 2
        eventsStackView.top(equalTo: eventsContainer)
        eventsStackView.bottom(equalTo: eventsContainer)
        eventsStackView.center(in: eventsContainer, orientation: .horizontal)
        eventsStackView.width(lessThanOrEqualTo: eventsContainer)

        let stack = NSStackView(views: [label, lunarLabel, eventsContainer])
            .with(orientation: .vertical)
            .with(alignment: .centerX)
            .with(spacing: 0)

        contentStackView = stack
        addSubview(stack)
        stack.clipsToBounds = false

        stack.center(in: self, orientation: .horizontal)
        stack.width(lessThanOrEqualTo: self)
        contentTopConstraint = stack.top(equalTo: self, constant: Constants.contentInset)
        contentTopConstraint.isActive = false
        contentCenterYConstraint = stack.center(in: self, orientation: .vertical)
    }

    private func applySecondaryLineLayout(_ expanded: Bool) {
        if expanded {
            contentCenterYConstraint.isActive = false
            contentTopConstraint.isActive = true
        } else {
            contentTopConstraint.isActive = false
            contentCenterYConstraint.isActive = true
        }
        contentStackView.spacing = expanded ? Constants.contentSpacing : 0
        eventsStackView.spacing = expanded ? Constants.contentSpacing : 2
        contentStackView.setHuggingPriority(expanded ? .required : .defaultLow, for: .vertical)
        needsLayout = true
        layoutSubtreeIfNeeded()
        updateBorderLayers()
    }

    private func updateBorderLayers() {
        borderLayer.frame = bounds
        restDayLayer.frame = bounds.insetBy(dx: 1, dy: 1)
    }

    override func layout() {
        super.layout()
        updateBorderLayers()
    }

    private func setUpBindings() {

        calendarScaling
            .bind { [weak self, borderLayer] in
                borderLayer.borderWidth = Constants.borderWidth * $0
                self?.updateLayer()
            }
            .disposed(by: disposeBag)

        viewModel
            .map(\.text)
            .distinctUntilChanged()
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .map(\.alpha)
            .distinctUntilChanged()
            .bind(to: label.rx.alpha)
            .disposed(by: disposeBag)

        viewModel
            .map(\.usesSecondaryLine)
            .distinctUntilChanged()
            .bind { [weak self] in
                self?.applySecondaryLineLayout($0)
            }
            .disposed(by: disposeBag)

        viewModel
            .map { vm -> String in
                if let text = vm.lunarText { return text }
                return vm.usesSecondaryLine ? " " : ""
            }
            .distinctUntilChanged()
            .bind(to: lunarLabel.rx.text)
            .disposed(by: disposeBag)

        viewModel
            .map(\.isLunarMonthStart)
            .distinctUntilChanged()
            .bind { [lunarLabel] isMonthStart in
                lunarLabel.font = .systemFont(
                    ofSize: Constants.lunarFontSize,
                    weight: isMonthStart ? .semibold : .regular
                )
            }
            .disposed(by: disposeBag)

        viewModel
            .map { vm in !vm.usesSecondaryLine }
            .distinctUntilChanged()
            .bind(to: lunarLabel.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel
            .map { vm -> CGFloat in
                guard vm.usesSecondaryLine else { return 0 }
                guard vm.lunarText != nil else { return 0 }
                return vm.alpha * (vm.isStatutoryRestDay || vm.holidayName != nil ? 0.9 : 0.7)
            }
            .distinctUntilChanged()
            .bind(to: lunarLabel.rx.alpha)
            .disposed(by: disposeBag)

        viewModel
            .map { vm -> NSColor in
                if vm.isStatutoryRestDay {
                    return NSColor.systemRed.withAlphaComponent(0.8)
                }
                if vm.isSolarTermDay {
                    return NSColor.systemBrown.withAlphaComponent(0.85)
                }
                if vm.holidayName != nil {
                    return NSColor.systemRed.withAlphaComponent(0.65)
                }
                return .secondaryLabelColor
            }
            .bind { [lunarLabel] in
                lunarLabel.textColor = $0
            }
            .disposed(by: disposeBag)

        viewModel
            .map(\.isStatutoryRestDay)
            .distinctUntilChanged()
            .bind { [restDayLayer] isRest in
                restDayLayer.backgroundColor = isRest
                    ? NSColor.systemRed.withAlphaComponent(0.08).cgColor
                    : nil
            }
            .disposed(by: disposeBag)

        viewModel
            .repeat(when: rx.updateLayer)
            .map(\.borderColor.effectiveCGColor)
            .distinctUntilChanged()
            .bind(to: borderLayer.rx.borderColor)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.map(\.dots).distinctUntilChanged(),
            textScaling
        )
        .repeat(when: rx.updateLayer)
        .map { dots, scaling in
            if dots.count <= CalendarCellViewModel.maximumDotsCount {
                dots.map {
                    makeEventDot(color: $0, scaling: scaling)
                }
            } else {
                [
                    makeEventsGradient(colors: dots, scaling: scaling)
                ]
            }
        }
        .bind(to: eventsStackView.rx.arrangedSubviews)
        .disposed(by: disposeBag)

        /// When we single-click a date, it updates the event list, which causes the window to resize.
        /// That causes the 2nd click to be cancelled by macOS, even though we're clicking at the exact same place.
        /// Because of that, we have to calculate the time difference between single clicks and trigger the double click ourselves:
        ///
        /// Expected behavior:
        ///  - If the user clicked a date in the current month, immediately fire the single click and the double click later, if detected.
        ///  - If the user clicked a date in another month, wait for the double click. If detected, cancel the single click.
        ///
        /// That avoids changing months during the double click, which ends up opening the system calendar in the wrong date.

        var lastClickTimestamp: TimeInterval = 0
        var workItem: DispatchWorkItem?

        rx.click
            .withLatestFrom(viewModel)
            .bind { [clickObserver, doubleClickObserver] vm in
                let currentTimestamp = CACurrentMediaTime()
                let doubleClicked = currentTimestamp - lastClickTimestamp < NSEvent.doubleClickInterval

                if vm.inMonth {
                    clickObserver.onNext(vm.date)
                } else if !doubleClicked {
                    workItem = DispatchWorkItem {
                        clickObserver.onNext(vm.date)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + NSEvent.doubleClickInterval, execute: workItem!)
                }

                if doubleClicked {
                    workItem?.cancel()
                    doubleClickObserver.onNext(vm.date)
                }

                lastClickTimestamp = currentTimestamp
            }
            .disposed(by: disposeBag)

        rx.mouseEntered
            .withLatestFrom(viewModel.map(\.date))
            .bind(to: hoverObserver)
            .disposed(by: disposeBag)
    }

    override func updateLayer() {
        super.updateLayer()
        updateBorderLayers()
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    // Prevent propagating event to superview
    override func mouseExited(with event: NSEvent) { }

    override func updateTrackingAreas() {

        if let trackingArea = trackingAreas.first {
            guard trackingArea.rect != bounds else { return }
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow],
            owner: self
        )

        addTrackingArea(trackingArea)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func makeEventsGradient(colors: [NSColor], scaling: Double) -> NSView {
    let view = NSView()
    let size = Constants.eventDotSize * scaling
    view.height(equalTo: size)
    view.width(equalTo: 4 * size, priority: .defaultHigh)

    let gradient = CAGradientLayer()
    gradient.colors = colors.map(\.cgColor)
    gradient.startPoint = CGPoint(x: 0, y: 0.5)
    gradient.endPoint = CGPoint(x: 1, y: 0.5)
    gradient.cornerRadius = size / 2

    view.layer = gradient

    return view
}

private func makeEventDot(color: NSColor, scaling: Double) -> NSView {

    let view = NSView()
    let size = Constants.eventDotSize * scaling

    view.size(equalTo: size)

    view.wantsLayer = true
    view.layer!.backgroundColor = color.effectiveCGColor
    view.layer!.cornerRadius = size / 2

    return view
}

private enum Constants {

    static let fontSize: CGFloat = 12
    static let lunarFontSize: CGFloat = 9
    static let eventDotSize: CGFloat = 3
    static let contentSpacing: CGFloat = 1
    static let contentInset: CGFloat = 2
    static let bottomInset: CGFloat = 2

    static let borderWidth: CGFloat = 2
    static let cornerRadius: CGFloat = 5
}
