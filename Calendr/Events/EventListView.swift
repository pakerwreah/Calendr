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

    private let stackView = NSStackView(.vertical)

    init(eventsObservable: Observable<[EventModel]>, dateProvider: DateProviding) {

        func sortTuple(_ event: EventModel) -> (Int, Date, Date) {
            (event.isAllDay ? 0 : 1, event.start, event.end)
        }

        eventsObservable
            .observe(on: MainScheduler.instance)
            .map { events in
                events
                    .sorted {
                        sortTuple($0) < sortTuple($1)
                    }
                    .map {
                        EventView(viewModel: EventViewModel(event: $0, dateProvider: dateProvider))
                    }
            }
            .map {
                $0.isEmpty ? [] : ([.spacer] + $0 + [.spacer])
            }
            .bind(to: stackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)

        super.init(frame: .zero)

        configureLayout()
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(stackView)

        stackView.edges(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
