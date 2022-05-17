//
//  EventStatusItemView.swift
//  Calendr
//
//  Created by Paker on 24/02/2021.
//

import Cocoa
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
        .map { $0 ? max($1 - 10, 0) : 0 }
        .distinctUntilChanged()

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()
    }

    private func configureLayout() {

        nextEventView.spacing = 4
        nextEventView.height(equalTo: Constants.height)
        nextEventView.wantsLayer = true
        nextEventView.layer?.cornerRadius = 4
        nextEventTitle.forceVibrancy = false

        [.dummy, colorBar, nextEventTitle, nextEventTime, .dummy].forEach(nextEventView.addArrangedSubview)

        colorBar.wantsLayer = true
        colorBar.layer?.cornerRadius = 1.5
        colorBar.width(equalTo: 3)
        colorBar.height(equalTo: nextEventView, constant: -4)

        nextEventTitle.textColor = .headerTextColor
        nextEventTitle.lineBreakMode = .byTruncatingTail

        nextEventTime.textColor = .headerTextColor
        nextEventTime.font = .systemFont(ofSize: 11)
        nextEventTime.setContentCompressionResistancePriority(.required, for: .horizontal)

        forAutoLayout()

        addSubview(nextEventView)

        nextEventView.edges(to: self)
    }

    private func setUpBindings() {

        viewModel.barColor
            .map(\.cgColor)
            .bind(to: colorBar.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel.backgroundColor
            .map(\.cgColor)
            .bind(to: nextEventView.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel.title
            .bind(to: nextEventTitle.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.time
            .bind(to: nextEventTime.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.hasEvent
            .map(!)
            .bind(to: rx.isHidden)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Constants {

    static let height: CGFloat = 20
}
