//
//  CalendarCellView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift
import RxCocoa

class CalendarCellView: NSView {
    private static let eventDotSize: CGFloat = 3

    private let contentStackView = NSStackView(.vertical)
    private let eventsStackView = NSStackView(.horizontal)
    private let label = Label()

    private let diposeBag = DisposeBag()

    init(dataObservable: Observable<CalendarCellViewModel>) {
        super.init(frame: .zero)
        wantsLayer = true

        forAutoLayout()

        configureLayout()

        setUpBindings(with: dataObservable)
    }

    private func configureLayout() {
        label.alignment = .center

        eventsStackView.spacing = 2
        eventsStackView.height(equalTo: Self.eventDotSize)

        contentStackView.spacing = 2
        contentStackView.addArrangedSubview(label)
        contentStackView.addArrangedSubview(eventsStackView)

        addSubview(contentStackView)

        contentStackView.center(in: self)

        label.size(equalTo: CGSize(width: 24, height: label.font!.pointSize))
    }

    private func setUpBindings(with dataObservable: Observable<CalendarCellViewModel>) {
        dataObservable
            .map(\.label)
            .bind(to: label.rx.string)
            .disposed(by: diposeBag)

        dataObservable
            .map(\.alpha)
            .bind(to: contentStackView.rx.alpha)
            .disposed(by: diposeBag)

        dataObservable
            .map(\.backgroundColor.cgColor)
            .bind(to: layer!.rx.backgroundColor)
            .disposed(by: diposeBag)

        dataObservable
            .map(\.events)
            .map { $0.map(\.color).map(Self.makeEventDot) }
            .bind(to: eventsStackView.rx.arrangedSubviews)
            .disposed(by: diposeBag)
    }

    private static func makeEventDot(color: NSColor) -> NSView {
        let view = NSView()
        view.size(equalTo: eventDotSize)
        view.wantsLayer = true
        view.layer.map { layer in
            layer.backgroundColor = color.cgColor
            layer.cornerRadius = eventDotSize / 2
        }
        return view
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
