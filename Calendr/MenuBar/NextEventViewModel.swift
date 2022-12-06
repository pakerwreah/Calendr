//
//  NextEventViewModel.swift
//  Calendr
//
//  Created by Paker on 24/02/2021.
//

import Cocoa
import RxSwift

class NextEventViewModel {

    let title: Observable<String>
    let time: Observable<String>
    let barStyle: Observable<EventBarStyle>
    let barColor: Observable<NSColor>
    let backgroundColor: Observable<NSColor>
    let hasEvent: Observable<Bool>
    let isInProgress: Observable<Bool>

    private let disposeBag = DisposeBag()
    private let event = BehaviorSubject<EventModel?>(value: nil)

    private let isShowingDetails: AnyObserver<Bool>

    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let popoverSettings: PopoverSettings
    private let workspace: WorkspaceServiceProviding

    init(
        settings: NextEventSettings,
        enabledCalendars: Observable<[String]>,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        workspace: WorkspaceServiceProviding,
        screenProvider: ScreenProviding,
        isShowingDetails: AnyObserver<Bool>,
        scheduler: SchedulerType,
        hoursToCheck: Int
    ) {

        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.popoverSettings = settings
        self.workspace = workspace
        self.isShowingDetails = isShowingDetails

        typealias NextEventTuple = (event: EventModel, isInProgress: Bool)

        let nextEventObservable = settings.showEventStatusItem
            .flatMapLatest { isEnabled -> Observable<[EventModel]> in

                !isEnabled ? .just([]) : enabledCalendars
                    .repeat(when: calendarService.changeObservable)
                    .flatMapLatest { calendars -> Observable<[EventModel]> in
                        let start = dateProvider.calendar.startOfDay(for: dateProvider.now)
                        let end = dateProvider.calendar.date(byAdding: .hour, value: 24 + hoursToCheck, to: start)!
                        return calendarService.events(from: start, to: end, calendars: calendars)
                    }
                    .map { $0.filter { !$0.isAllDay && ![.pending, .declined].contains($0.status) } }
            }
            .distinctUntilChanged()
            .flatMapLatest { [dateProvider] events -> Observable<NextEventTuple?> in

                Observable<Int>.interval(.seconds(1), scheduler: scheduler)
                    .void()
                    .startWith(())
                    .map {
                        events
                            .first(where: { event in
                                dateProvider.calendar.isDate(
                                    dateProvider.now, lessThan: event.end, granularity: .second
                                )
                                &&
                                Int(dateProvider.now.distance(to: event.start)) <= 3600 * hoursToCheck
                            })
                            .map { event -> NextEventTuple in
                                let isInProgress = dateProvider.calendar.isDate(
                                    dateProvider.now, greaterThanOrEqualTo: event.start, granularity: .second
                                )
                                return (event, isInProgress)
                            }
                    }
            }
            .share(replay: 1)

        nextEventObservable
            .map(\.?.event)
            .bind(to: event)
            .disposed(by: disposeBag)

        isInProgress = nextEventObservable.map { $0?.isInProgress ?? false }

        barColor = event
            .skipNil()
            .map(\.calendar.color)
            .distinctUntilChanged()

        barStyle = event
            .skipNil()
            .map { $0.type ~= .event(.maybe) ? .bordered : .filled }
            .distinctUntilChanged()

        backgroundColor = nextEventObservable
            .skipNil()
            .map { $0.isInProgress ? $0.event.calendar.color.withAlphaComponent(0.2): .clear }
            .distinctUntilChanged()

        let shouldCompact = Observable
            .combineLatest(settings.eventStatusItemDetectNotch, screenProvider.hasNotchObservable)
            .map { $0 && $1 }
            .distinctUntilChanged()

        let eventStatusItemLength = Observable
            .combineLatest(shouldCompact, settings.eventStatusItemLength)
            .map { $0 ? min($1, Constants.compactMaxWidth) : $1 }

        let nextEventTitle = event.skipNil().map(\.title)

        title = Observable.combineLatest(nextEventTitle, eventStatusItemLength, shouldCompact)
            .map { $0.count > $1 ? "\($0.prefix($1).trimmed)\($2 ? "." : "...")": $0 }
            .distinctUntilChanged()

        let dateFormatter = DateComponentsFormatter()
        dateFormatter.calendar = dateProvider.calendar
        dateFormatter.unitsStyle = .abbreviated
        dateFormatter.maximumUnitCount = 2

        time = nextEventObservable
            .skipNil()
            .map { [dateProvider] event, isInProgress in

                dateFormatter.allowedUnits = [.hour, .minute]

                var date = isInProgress && !event.type.isReminder ? event.end : event.start

                let diff = dateProvider.calendar.dateComponents([.minute, .second], from: dateProvider.now, to: date)

                if diff.minute == 0, diff.second! <= 30 {
                    dateFormatter.allowedUnits = [.second]
                }
                else if diff.second! > 0 {
                    dateProvider.calendar.date(byAdding: .minute, value: 1, to: date).map { date = $0 }
                }

                let time: String

                if !isInProgress {
                    time = Strings.Formatter.Date.Relative.in(
                        dateFormatter.string(from: dateProvider.now, to: date) ?? ""
                    )
                }
                else if event.type.isReminder {
                    time = Strings.Formatter.Date.Relative.ago(
                        dateFormatter.string(from: date, to: dateProvider.now) ?? ""
                    )
                }
                else {
                    time = Strings.Formatter.Date.Relative.left(
                        dateFormatter.string(from: dateProvider.now, to: date) ?? ""
                    )
                }

                return time
            }
            .distinctUntilChanged()

        hasEvent = nextEventObservable
            .map(\.isNotNil)
            .distinctUntilChanged()
    }

    func makeDetails() -> EventDetailsViewModel? {
        guard let event = try? event.value() else { return nil }
        return .init(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            popoverSettings: popoverSettings,
            isShowingObserver: isShowingDetails,
            isInProgress: isInProgress
        )
    }
}

private enum Constants {

    static let compactMaxWidth = 15
}
