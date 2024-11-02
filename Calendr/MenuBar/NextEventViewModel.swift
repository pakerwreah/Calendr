//
//  NextEventViewModel.swift
//  Calendr
//
//  Created by Paker on 24/02/2021.
//

import Cocoa
import RxSwift

enum NextEventType {
    case event
    case reminder
}

private extension NextEventType {

    func matches(_ type: EventType) -> Bool {
        switch (self, type) {
        case (.event, .event), (.reminder, .reminder):
            return true
        default:
            return false
        }
    }
}

// prevent growing indefinitely
private let MAX_SKIPPED = 10

private struct Skipped: Equatable {
    let id: String
    let start: Date

    init(_ event: EventModel) {
        id = event.id
        start = event.start
    }
}

private struct NextEvent: Equatable {
    let event: EventModel
    let isInProgress: Bool
}

class NextEventViewModel {

    let title: Observable<String>
    let time: Observable<String>
    let fontSize: Observable<Float>
    let barStyle: Observable<EventBarStyle>
    let barColor: Observable<NSColor>
    let backgroundColor: Observable<NSColor>
    let hasEvent: Observable<Bool>
    let isInProgress: Observable<Bool>

    private let disposeBag = DisposeBag()
    private let event = BehaviorSubject<EventModel?>(value: nil)
    private let skippedEvents = BehaviorSubject<[Skipped]>(value: [])
    private let actionCallback = PublishSubject<ContextCallbackAction>()

    private let isShowingDetails: AnyObserver<Bool>

    private let type: NextEventType
    private let userDefaults: UserDefaults
    private let settings: EventDetailsSettings
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let geocoder: GeocodeServiceProviding
    private let weatherService: WeatherServiceProviding
    private let workspace: WorkspaceServiceProviding

    init(
        type: NextEventType,
        userDefaults: UserDefaults,
        settings: NextEventSettings,
        nextEventCalendars: Observable<[String]>,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        geocoder: GeocodeServiceProviding,
        weatherService: WeatherServiceProviding,
        workspace: WorkspaceServiceProviding,
        screenProvider: ScreenProviding,
        isShowingDetails: AnyObserver<Bool>,
        scheduler: SchedulerType,
        soundPlayer: SoundPlaying
    ) {

        self.type = type
        self.userDefaults = userDefaults
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.geocoder = geocoder
        self.weatherService = weatherService
        self.settings = settings
        self.workspace = workspace
        self.isShowingDetails = isShowingDetails
        self.fontSize = settings.eventStatusItemFontSize

        let nextEvents = settings.showEventStatusItem
            .flatMapLatest { isEnabled -> Observable<[EventModel]> in

                !isEnabled ? .just([]) : nextEventCalendars
                    .repeat(when: calendarService.changeObservable)
                    .flatMapLatest { calendars -> Single<[EventModel]> in
                        let start = dateProvider.calendar.startOfDay(for: dateProvider.now)
                        let end = dateProvider.calendar.date(byAdding: .hour, value: 48, to: start)!
                        return calendarService.events(from: start, to: end, calendars: calendars)
                    }
                    .map {
                        $0.filter { $0.type != .reminder(completed: true) }
                    }
            }

        let eventsObservable = Observable.combineLatest(nextEvents, skippedEvents)
            .map { events, skipped in
                events.filter { event in
                    !event.isAllDay &&
                    ![.pending, .declined].contains(event.status) &&
                    !skipped.contains(Skipped(event))
                }
            }

        let nextEventObservable = Observable
            .combineLatest(eventsObservable, settings.eventStatusItemCheckRange)
            .flatMapLatest { [dateProvider] events, hoursToCheck -> Observable<NextEvent?> in

                Observable<Int>.interval(.seconds(1), scheduler: scheduler)
                    .void()
                    .startWith(())
                    .map {
                        events
                            .sorted(by: \.start)
                            .first(where: { event in
                                type.matches(event.type)
                                &&
                                dateProvider.calendar.isDate(
                                    dateProvider.now, lessThan: event.end, granularity: .second
                                )
                                &&
                                Int(dateProvider.now.distance(to: event.start)) <= 3600 * hoursToCheck
                            })
                            .map { event -> NextEvent in
                                let isInProgress = dateProvider.calendar.isDate(
                                    dateProvider.now, greaterThanOrEqualTo: event.start, granularity: .second
                                )
                                return NextEvent(event: event, isInProgress: isInProgress)
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
            .map { [dateProvider] nextEvent in

                guard !nextEvent.isInProgress else {
                    return nextEvent.event.calendar.color.withAlphaComponent(0.2)
                }

                let diff = dateProvider.calendar.dateComponents([.minute, .second], from: dateProvider.now, to: nextEvent.event.start)

                guard let minutes = diff.minute, let seconds = diff.second else { return .clear }

                // play when event starts
                if minutes == 0 && seconds == 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                        soundPlayer.play(.glass)
                    }
                }

                // play at 5 minutes + 1 minute to start
                if [1, 5].contains(minutes) && seconds == 0 {
                    soundPlayer.play(.ping)
                }

                // flash continuously under 30 seconds to start
                if minutes == 0 && seconds <= 30 {
                    return seconds % 2 == 0 ? .systemRed : .clear
                }

                // flash 5x every minute
                if minutes <= 5 {
                    return seconds > 50 && seconds % 2 == 1 ? .systemRed : .clear
                }

                return .clear
            }
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
            .map { [dateProvider] nextEvent in

                let event = nextEvent.event
                let isInProgress = nextEvent.isInProgress

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

        actionCallback
            .matching(.event(.skip))
            .withLatestFrom(
                Observable.combineLatest(event, skippedEvents)
            )
            .compactMap { event, skipped in
                guard let event else { return nil }
                let result = skipped + [Skipped(event)]
                return result.suffix(MAX_SKIPPED)
            }
            .bind(to: skippedEvents)
            .disposed(by: disposeBag)
    }

    func makeContextMenuViewModel() -> (any ContextMenuViewModel)? {
        guard let event = try? event.value() else { return nil }
        return ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: .menubar,
            callback: actionCallback.asObserver()
        )
    }

    func makeDetailsViewModel() -> EventDetailsViewModel? {
        guard let event = try? event.value() else { return nil }
        return .init(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            geocoder: geocoder,
            weatherService: weatherService,
            workspace: workspace,
            userDefaults: userDefaults,
            settings: settings,
            isShowingObserver: isShowingDetails,
            isInProgress: isInProgress,
            source: .menubar,
            callback: actionCallback.asObserver()
        )
    }

    private var preferredPositionKey: String {
        let name: String
        switch type {
        case .event:
            name = StatusItemName.event
        case .reminder:
            name = StatusItemName.reminder
        }
        return "\(Prefs.statusItemPreferredPosition) \(name)"
    }

    func saveStatusItemPreferredPosition() {
        let position = userDefaults.integer(forKey: preferredPositionKey)
        userDefaults.set(position, forKey: "saved \(preferredPositionKey)")
    }

    func restoreStatusItemPreferredPosition() {
        let position = userDefaults.integer(forKey: "saved \(preferredPositionKey)")
        userDefaults.set(position, forKey: preferredPositionKey)
    }
}

private enum Constants {

    static let compactMaxWidth = 15
}
