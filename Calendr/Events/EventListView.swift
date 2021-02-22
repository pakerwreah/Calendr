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

    private let eventsObservable: Observable<[EventModel]>

    private let dateProvider: DateProviding
    private let workspaceProvider: WorkspaceProviding
    private let settings: SettingsViewModel

    private let contentStackView = NSStackView(.vertical)

    init(
        eventsObservable: Observable<[EventModel]>,
        dateProvider: DateProviding,
        workspaceProvider: WorkspaceProviding,
        settings: SettingsViewModel
    ) {

        self.eventsObservable = eventsObservable
        self.dateProvider = dateProvider
        self.workspaceProvider = workspaceProvider
        self.settings = settings

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

        eventsObservable
            .observe(on: MainScheduler.instance)
            .map { [dateProvider, workspaceProvider, settings] events in
                events
                    .sorted {
                        sortTuple($0) < sortTuple($1)
                    }
                    .map {
                        EventView(
                            viewModel: EventViewModel(
                                event: $0,
                                dateProvider: dateProvider,
                                workspaceProvider: workspaceProvider,
                                settings: settings
                            )
                        )
                    }
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
