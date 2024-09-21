//
//  EventListView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import Cocoa
import RxSwift

class EventListView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: EventListViewModel

    private let contentStackView = NSStackView(.vertical)

    init(viewModel: EventListViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.EventList.view)
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(contentStackView)

        contentStackView.edges(equalTo: self)
    }

    private func setUpBindings() {

        viewModel.asObservable()
            .observe(on: MainScheduler.instance)
            .withUnretained(self)
            .map { view, items in
                items.map { (item: EventListItem) -> NSView in
                    switch item {
                    case .event(let viewModel):
                        return EventView(viewModel: viewModel)

                    case .section(let text):
                        return view.makeSection(text)

                    case .interval(let text, let fade):
                        return EventIntervalView(text, fade)
                    }
                }
            }
            .bind(to: contentStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)

        viewModel.asObservable()
            .observe(on: MainScheduler.instance)
            .map(\.isEmpty)
            .bind(to: rx.isHidden)
            .disposed(by: disposeBag)
    }

    private func makeLine() -> NSView {

        let line = NSView.spacer(height: 1)
        line.wantsLayer = true

        line.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.effectiveCGColor }
            .bind(to: line.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        return line
    }

    private func makeSection(_ text: String) -> NSStackView {

        let line1 = makeLine()
        let line2 = makeLine()

        defer {
            line2.width(equalTo: line1)
        }

        let label = Label(text: text, font: .systemFont(ofSize: 10), color: .secondaryLabelColor)

        return NSStackView(views: [.dummy, line1, label, line2, .dummy]).with(alignment: .centerY)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
