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

        forAutoLayout()

        configureLayout()

        setUpBindings(with: viewModel)
    }

    private func configureLayout() {
        wantsLayer = true
        layer!.borderWidth = 2
        layer!.cornerRadius = 5

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
            .bind(to: label.rx.alpha)
            .disposed(by: disposeBag)

        viewModel
            .map(\.borderColor)
            .bind(to: layer!.rx.borderColor)
            .disposed(by: disposeBag)

        viewModel
            .map(\.dots)
            .map { $0.map(Self.makeEventDot) }
            .bind(to: eventsStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }

    private static func makeEventDot(color: CGColor) -> NSView {
        let view = NSView()
        view.size(equalTo: eventDotSize)
        view.wantsLayer = true
        view.layer.map { layer in
            layer.backgroundColor = color
            layer.cornerRadius = eventDotSize / 2
        }
        return view
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
