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

        func sortTuple(_ event: EventModel) -> (Int, Date, Date) {
            (event.isAllDay ? 0 : 1, event.start, event.end)
        }

        viewModel.asObservable()
            .observe(on: MainScheduler.instance)
            .map {
                $0.map(EventView.init)
            }
            .map {
                $0.isEmpty ? [] : ([.spacer] + $0 + [.spacer])
            }
            .bind(to: contentStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
