//
//  EventStatusItemView.swift
//  Calendr
//
//  Created by Paker on 24/02/2021.
//

import RxCocoa
import RxSwift

class NextEventView: NSView {

    private let disposeBag = DisposeBag()

    let widthObservable: Observable<CGFloat>

    private let viewModel: NextEventViewModel

    private let colorBar = NSView()
    private let nextEventTitle = Label()
    private let nextEventTime = Label()
    private let nextEventView = NSStackView()

    init(viewModel: NextEventViewModel) {

        self.viewModel = viewModel

        widthObservable = Observable.combineLatest(
            viewModel.hasEvent,
            nextEventView.rx.observe(\.frame).map(\.width)
        )
        .map { $0 ? min($1, Constants.maxWidth) - 14: 0 }
        .distinctUntilChanged()

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()
    }

    private func configureLayout() {

        colorBar.wantsLayer = true
        colorBar.layer?.cornerRadius = 1.5
        colorBar.width(equalTo: 3)

        nextEventTitle.lineBreakMode = .byTruncatingTail

        nextEventTime.setContentCompressionResistancePriority(.required, for: .horizontal)

        nextEventView.spacing = 4
        [
            .spacer(width: 0), colorBar, nextEventTitle, nextEventTime, .spacer(width: 0)
        ]
        .forEach(nextEventView.addArrangedSubview)

        colorBar.height(equalTo: nextEventView, constant: -4)

        nextEventView.height(equalTo: Constants.height)
        nextEventView.widthAnchor.constraint(lessThanOrEqualToConstant: Constants.maxWidth).activate()
        nextEventView.setCustomSpacing(0, after: nextEventTitle)
        nextEventView.wantsLayer = true
        nextEventView.layer?.cornerRadius = 4

        forAutoLayout()

        addSubview(nextEventView)

        nextEventView.edges(to: self)
    }

    private func setUpBindings() {

        viewModel.barColor
            .bind(to: colorBar.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel.backgroundColor
            .bind(to: nextEventView.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel.title
            .map { "\($0) " }
            .bind(to: nextEventTitle.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.time
            .bind(to: nextEventTime.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.hasEvent
            .map(\.isFalse)
            .bind(to: rx.isHidden)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Constants {

    static let height: CGFloat = 20
    static let maxWidth: CGFloat = 180
}
