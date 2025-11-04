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

    private let updateSubject = PublishSubject<Void>()
    let viewUpdated: Observable<Void>

    private let viewModel: NextEventViewModel

    private let colorBar = NSView()
    private let nextEventTitle: Label
    private let nextEventTime: Label
    private let nextEventView = NSStackView()

    init(viewModel: NextEventViewModel) {

        self.viewModel = viewModel

        viewUpdated = updateSubject
            .debounce(.milliseconds(50), scheduler: MainScheduler.instance)
            .startWith(())

        let scaling = viewModel.textScaling.track(with: updateSubject)

        let font = NSFont.systemFont(ofSize: 10)
        nextEventTitle = Label(font: font, scaling: scaling)
        nextEventTime = Label(font: font, scaling: scaling)

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
        nextEventTitle.setContentCompressionResistancePriority(.required, for: .horizontal)
        nextEventTitle.setContentHuggingPriority(.required, for: .horizontal)

        nextEventTime.center(in: nextEventTitle, orientation: .vertical)
        nextEventTime.textColor = .headerTextColor
        nextEventTime.setContentCompressionResistancePriority(.required, for: .horizontal)
        nextEventTime.setContentHuggingPriority(.required, for: .horizontal)

        forAutoLayout()

        setContentHuggingPriority(.required, for: .horizontal)
        nextEventView.setContentHuggingPriority(.required, for: .horizontal)
        nextEventView.setHuggingPriority(.required, for: .horizontal)

        addSubview(nextEventView)

        nextEventView.edges(equalTo: self)
    }

    private func setUpBindings() {

        Observable.combineLatest(
            viewModel.barStyle,
            viewModel.barColor.map(\.cgColor)
        )
        .track(with: updateSubject)
        .bind(to: colorBar.layer!.rx.eventBarStyle)
        .disposed(by: disposeBag)

        viewModel.backgroundColor
            .map(\.cgColor)
            .track(with: updateSubject)
            .bind(to: nextEventView.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel.title
            .track(with: updateSubject)
            .bind(to: nextEventTitle.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.time
            .track(with: updateSubject)
            .bind(to: nextEventTime.rx.stringValue)
            .disposed(by: disposeBag)

        viewModel.hasEvent
            .map(!)
            .track(with: updateSubject)
            .bind(to: rx.isHidden)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ObservableType {

    func track<Observer: ObserverType>(with observer: Observer) -> Observable<Element> where Observer.Element == Void {
        self.do(afterNext: { _ in
            observer.onNext(())
        })
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
