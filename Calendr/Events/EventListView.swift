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

    init(eventsObservable: Observable<[EventModel]>) {

        eventsObservable.map {
            $0.map {
                EventView(viewModel: EventViewModel(event: $0))
            }
        }
        .bind(to: stackView.rx.arrangedSubviews)
        .disposed(by: disposeBag)

        super.init(frame: .zero)

        configureLayout()
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(stackView)

        stackView
            .leading(equalTo: self)
            .trailing(equalTo: self)
            .top(equalTo: self, constant: 4)
            .bottom(equalTo: self, constant: 4)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
