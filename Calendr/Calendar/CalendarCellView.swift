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

    private let disposeBag = DisposeBag()

    init(viewModel: Observable<CalendarCellViewModel>) {
        super.init(frame: .zero)
        wantsLayer = true

        forAutoLayout()

        configureLayout()

        setUpBindings(with: viewModel)
    }

    private func configureLayout() {
        label.alignment = .center
        label.size(equalTo: CGSize(width: 24, height: 13))

        eventsStackView.spacing = 2
        eventsStackView.height(equalTo: Self.eventDotSize)

        let eventsContainer = NSView()
        eventsContainer.addSubview(eventsStackView)
        eventsStackView
            .top(equalTo: eventsContainer)
            .bottom(equalTo: eventsContainer)
            .center(in: eventsContainer, orientation: .horizontal)

        contentStackView.spacing = 2
        contentStackView.addArrangedSubviews(label, eventsContainer)

        addSubview(contentStackView)

        contentStackView.center(in: self)
    }

    private func setUpBindings(with viewModel: Observable<CalendarCellViewModel>) {
        viewModel
            .map(\.text)
            .bind(to: label.rx.string)
            .disposed(by: disposeBag)

        viewModel
            .map(\.alpha)
            .bind(to: contentStackView.rx.alpha)
            .disposed(by: disposeBag)

        viewModel
            .map(\.backgroundColor.cgColor)
            .bind(to: layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        viewModel
            .map(\.events)
            .map { $0.map(\.color).map(Self.makeEventDot) }
            .bind(to: eventsStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)
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
