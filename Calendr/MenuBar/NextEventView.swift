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

        nextEventTitle.center(in: nextEventView, orientation: .vertical)
        nextEventTitle.textColor = .headerTextColor
        nextEventTitle.lineBreakMode = .byTruncatingTail

        nextEventTime.center(in: nextEventTitle, orientation: .vertical)
        nextEventTime.textColor = .headerTextColor
        nextEventTime.setContentCompressionResistancePriority(.required, for: .horizontal)

        forAutoLayout()

        addSubview(nextEventView)

        nextEventView.edges(equalTo: self)
    }

    private func setUpBindings() {

        let fontSizeObservable = viewModel.textScaling
            .map { NSFont.systemFont(ofSize: 10 * CGFloat($0)) }
            .share(replay: 1)

        fontSizeObservable
            .bind(to: nextEventTitle.rx.font)
            .disposed(by: disposeBag)

        fontSizeObservable
            .bind(to: nextEventTime.rx.font)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.barStyle,
            viewModel.barColor.map(\.cgColor)
        )
        .bind(to: colorBar.layer!.rx.eventBarStyle)
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

private extension Reactive where Base: CALayer {

    var eventBarStyle: Binder<(EventBarStyle, CGColor)> {

        Binder(self.base) { layer, values in
            let (style, color) = values

            switch style {
            case .filled:
                layer.borderWidth = 0
                layer.borderColor = nil
                layer.backgroundColor = color

            case .bordered:
                layer.borderWidth = 1
                layer.borderColor = color
                layer.backgroundColor = nil
            }
        }
    }
}

private enum Constants {

    static let height: CGFloat = 20
}
