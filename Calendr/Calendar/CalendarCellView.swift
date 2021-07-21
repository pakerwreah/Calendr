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

    private let label = Label()
    private let eventsStackView = NSStackView()
    private let borderLayer = CALayer()

    init(
        viewModel: Observable<CalendarCellViewModel>,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>
    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)

        Observable.combineLatest(
            viewModel.map(\.isToday).distinctUntilChanged(),
            viewModel.map(\.isSelected).distinctUntilChanged(),
            viewModel.map(\.isHovered).distinctUntilChanged()
        )
        .map { isToday, isSelected, isHovered in
            [
                Accessibility.Calendar.date,
                isToday ? Accessibility.Calendar.today : nil,
                isSelected ? Accessibility.Calendar.selected : nil,
                isHovered ? Accessibility.Calendar.hovered : nil
            ]
            .compact()
        }
        .bind(to: rx.accessibilityIdentifiers)
        .disposed(by: disposeBag)
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        borderLayer.borderWidth = 2
        borderLayer.cornerRadius = 5
        layer!.addSublayer(borderLayer)

        label.alignment = .center
        label.font = .systemFont(ofSize: 12)
        label.size(equalTo: CGSize(width: 24, height: 13))
        label.textColor = .headerTextColor

        let eventsContainer = NSView()
        eventsContainer.addSubview(eventsStackView)

        eventsStackView.spacing = 2
        eventsStackView.top(equalTo: eventsContainer)
        eventsStackView.bottom(equalTo: eventsContainer)
        eventsStackView.center(in: eventsContainer, orientation: .horizontal)
        eventsStackView.height(equalTo: Constants.eventDotSize)

        let contentStackView = NSStackView(views: [label, eventsContainer])
            .with(orientation: .vertical)
            .with(spacing: 2)

        addSubview(contentStackView)

        contentStackView.center(in: self)
    }

    private func setUpBindings() {

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
            .repeat(when: rx.updateLayer)
            .map(\.borderColor.cgColor)
            .distinctUntilChanged()
            .bind(to: borderLayer.rx.borderColor)
            .disposed(by: disposeBag)

        viewModel
            .map(\.dots)
            .distinctUntilChanged()
            .compactMap { $0?.map(makeEventDot) }
            .bind(to: eventsStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)

        rx.leftClickGesture()
            .when(.recognized)
            .withLatestFrom(viewModel.map(\.date))
            .bind(to: clickObserver)
            .disposed(by: disposeBag)

        Observable.merge(
            rx.mouseEntered.withLatestFrom(viewModel.map(\.date)).toOptional(),
            rx.mouseExited.map(nil)
        )
        .bind(to: hoverObserver)
        .disposed(by: disposeBag)
    }

    override func updateLayer() {
        super.updateLayer()
        borderLayer.frame = bounds
    }

    override func updateTrackingAreas() {
        trackingAreas.forEach(removeTrackingArea(_:))
        addTrackingRect(bounds, owner: self, userData: nil, assumeInside: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func makeEventDot(color: NSColor) -> NSView {

    let view = NSView()

    view.size(equalTo: Constants.eventDotSize)

    view.wantsLayer = true

    view.layer.map { layer in
        layer.backgroundColor = color.cgColor
        layer.cornerRadius = Constants.eventDotSize / 2
    }

    if BuildConfig.isUITesting {
        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Calendar.event)
    }

    return view
}

private enum Constants {

    static let eventDotSize: CGFloat = 3
}
