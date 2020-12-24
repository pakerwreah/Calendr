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
    private let contentStackView = NSStackView()
    private let eventsStackView = NSStackView()
    private let label = NSTextView()

    private let diposeBag = DisposeBag()

    init(dataObservable: Observable<CalendarCellViewModel>) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        configureLayout()

        setUpBindings(with: dataObservable)
    }

    private func configureLayout() {
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let labelContainer = NSView(frame: .zero)
        labelContainer.addSubview(label)

        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: label.font!.pointSize),
            label.widthAnchor.constraint(equalTo: labelContainer.widthAnchor),
            label.centerYAnchor.constraint(equalTo: labelContainer.centerYAnchor)
        ])

        eventsStackView.setContentHuggingPriority(.required, for: .vertical)

        contentStackView.orientation = .vertical
        contentStackView.addArrangedSubview(labelContainer)
        contentStackView.addArrangedSubview(eventsStackView)

        addSubview(contentStackView)

        contentStackView.edges(to: self)
    }

    private func setUpBindings(with dataObservable: Observable<CalendarCellViewModel>) {
        dataObservable
            .map(\.label)
            .bind(to: label.rx.string)
            .disposed(by: diposeBag)

        dataObservable
            .map(\.events)
            .map {
                $0.map(\.color).map(Self.makeEventDot)
            }
            .subscribe(onNext: { [eventsStackView] events in
                eventsStackView.isHidden = events.isEmpty
                eventsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                events.forEach(eventsStackView.addArrangedSubview)
            })
            .disposed(by: diposeBag)
    }

    private static func makeEventDot(color: NSColor) -> NSView {
        let size: CGFloat = 10
        let view = NSView(frame: NSRect(origin: .zero, size: CGSize(width: size, height: size)))
        view.wantsLayer = true
        view.layer.map { layer in
            layer.backgroundColor = color.cgColor
            layer.cornerRadius = size / 2
        }
        return view
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
