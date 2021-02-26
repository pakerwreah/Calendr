//
//  EventListViewModel.swift
//  Calendr
//
//  Created by Paker on 26/02/2021.
//

import RxCocoa
import RxSwift

class EventListViewModel {

    private let viewModels: Observable<[EventViewModel]>

    init(
        eventsObservable: Observable<[EventModel]>,
        dateProvider: DateProviding,
        workspaceProvider: WorkspaceProviding,
        settings: EventSettings
    ) {

        func sortTuple(_ event: EventModel) -> (Int, Date, Date) {
            (event.isAllDay ? 0 : 1, event.start, event.end)
        }

        viewModels = eventsObservable
            .map { events in
                events
                    .sorted {
                        sortTuple($0) < sortTuple($1)
                    }
                    .map {
                        EventViewModel(
                            event: $0,
                            dateProvider: dateProvider,
                            workspaceProvider: workspaceProvider,
                            settings: settings
                        )
                    }
            }
            .share(replay: 1)
    }

    func asObservable() -> Observable<[EventViewModel]> {
        return viewModels
    }
}
