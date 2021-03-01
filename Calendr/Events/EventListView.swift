//
//  EventListView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import RxCocoa
import RxSwift

class EventListView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: EventListViewModel

    private let contentStackView = NSStackView(.vertical)

    init(viewModel: EventListViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(contentStackView)

        contentStackView.edges(to: self)
    }

    private func setUpBindings() {

        viewModel.asObservable()
            .observe(on: MainScheduler.instance)
            .map {
                $0.map { (item: EventListItem) -> NSView in
                    switch item {
                    case .event(let viewModel):
                        return EventView(viewModel: viewModel)

                    case .section(let text):
                        return makeSection(text)

                    case .interval(let text, let fade):
                        return EventIntervalView(text, fade)
                    }
                }
            }
            .bind(to: contentStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func makeLine() -> NSView {

    let line = NSView.spacer(height: 1)
    line.wantsLayer = true
    line.layer?.backgroundColor = NSColor.quaternaryLabelColor.cgColor

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
