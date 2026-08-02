//
//  EventDetailsViewModel.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Cocoa
import RxSwift

enum EventDetailsSource {
    case calendar
    case menubar
}

class EventDetailsViewModel {

    let type: EventType
    let status: EventStatus
    let title: String
    let duration: String
    let url: String
    let location: String
    let notes: String?
    let meetingInfo: String?
    let participants: [Participant]
    let link: EventLink?
    let settings: EventSettings
    let showSkip: Bool
    let optimisticLoadTime: DispatchTimeInterval
    let attachments: [Attachment]

    let canShowMap: Bool
    let coordinates: Maybe<Coordinates>
    let weather: Maybe<(Weather, isAllDay: Bool)>
    let isInProgress: Observable<Bool>
    let close: Completable

    let linkTapped: AnyObserver<Void>
    let openTapped: AnyObserver<Void>
    let skipTapped: AnyObserver<Void>
    let openAttachment: AnyObserver<Attachment>
    let openMaps: AnyObserver<Coordinates>
    let isShowingObserver: AnyObserver<Bool>

    let browserPickerViewModel: BrowserPickerViewModel

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let workspace: WorkspaceServiceProviding

    private let callback: AnyObserver<ContextCallbackAction>

    private let disposeBag = DisposeBag()

    init(
        source: EventDetailsSource,
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        geocoder: GeocodeServiceProviding,
        weatherService: WeatherServiceProviding,
        workspace: WorkspaceServiceProviding,
        localStorage: LocalStorageProvider,
        settings: EventSettings,
        isShowingObserver: AnyObserver<Bool>,
        callback: AnyObserver<ContextCallbackAction>,
        scheduler: SchedulerType
    ) {
        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.settings = settings
        self.isShowingObserver = isShowingObserver
        self.workspace = workspace

        browserPickerViewModel = BrowserPickerViewModel(
            calendarId: event.calendar.id,
            workspace: workspace,
            localStorage: localStorage,
            source: .event
        )

        type = event.type
        status = event.status
        title = event.title
        attachments = event.attachments
        link = event.detectLink(using: workspace)
        url = type.isBirthday ? "" : link.map { $0.isNative ? "" : $0.original.absoluteString } ?? ""
        location = event.location ?? ""
        (notes, meetingInfo) = parseNotesMeetingInfo(from: event.notes)
        participants = event.participants.sorted {
            ($0.isOrganizer, $0.isCurrentUser, $0.status, $0.name)
            <
            ($1.isOrganizer, $1.isCurrentUser, $1.status, $1.name)
        }

        linkTapped = .init { [link] _ in
            if let link {
                workspace.open(link)
            }
        }

        openAttachment = .init { event in
            if let attachment = event.element {
                workspace.open(attachment)
            }
        }

        openMaps = .init {
            guard
                let c = $0.element,
                var url = URLComponents(string: "maps://")
            else { return }

            url.queryItems = [
                URLQueryItem(name: "ll", value: "\(c.latitude),\(c.longitude)"),
                URLQueryItem(name: "q", value: event.title),
            ]

            if let url = url.url {
                workspace.open(url)
            }
        }

        showSkip = source == .menubar && type.isEvent

        duration = EventDuration.duration(
            for: event,
            using: dateProvider,
            preferredDateStyle: .medium,
            preferredTimeStyle: .short,
            forceLocalTimeZone: settings.forceLocalTimeZone.lastValue() ?? false
        )

        let closeSubject = PublishSubject<Never>()

        close = closeSubject.asCompletable()

        self.callback = callback.mapObserver {
            closeSubject.onCompleted()
            return $0
        }

        skipTapped = self.callback.mapObserver { _ in
            // handled by NextEventViewModel
            return .event(event, .skip)
        }

        openTapped = .init { _ in
            workspace.open(event)
        }

        canShowMap = { [location] (showMap: Bool) in
            guard showMap, !location.isEmpty else { return false }

            let blacklist = ["://", "www."] + localStorage.showMapBlacklistItems

            let isBlacklisted = blacklist.contains {
                location.localizedCaseInsensitiveContains($0)
            }

            guard !isBlacklisted else { return false }

            if let pattern = localStorage.showMapBlacklistRegex, pattern.isNotBlank {
                do {
                    return try Regex(pattern).firstMatch(in: location) == nil
                } catch {
                    if !BuildConfig.isTesting {
                        print(error.localizedDescription)
                    }
                }
            }
            return true
        }(settings.showMap.lastValue() ?? false)

        coordinates = Maybe.create { [canShowMap, location] observer in
            Task {
                guard canShowMap else {
                    observer(.completed)
                    return
                }
                if let coordinates = event.coordinates {
                    observer(.success(coordinates))
                    return
                }
                if let coordinates = await geocoder.geocodeLocation(location) {
                    observer(.success(coordinates))
                    return
                }
                observer(.completed)
            }
            return Disposables.create()
        }
        .asObservable()
        .share(replay: 1, scope: .forever)
        .asMaybe()

        // trigger early fetch and keep value
        coordinates.subscribe().disposed(by: disposeBag)

        weather = coordinates.flatMap { coordinates in
            Maybe.create { observer in
                Task {
                    guard let weather = await weatherService.weather(for: coordinates, on: event.start) else {
                        observer(.completed)
                        return
                    }
                    observer(.success((weather, event.isAllDay)))
                }
                return Disposables.create()
            }
        }
        .asObservable()
        .share(replay: 1, scope: .forever)
        .asMaybe()

        // trigger early fetch and keep value
        weather.subscribe().disposed(by: disposeBag)

        optimisticLoadTime = .milliseconds(canShowMap && !event.location.isNilOrEmpty ? 50 : 0)

        func distance(to date: Date) -> Int {
            Int(dateProvider.now.distance(to: date).rounded(.up))
        }

        let secondsToStart = distance(to: event.start)
        let secondsToEnd = distance(to: event.end)
        let isAlreadyInProgress = secondsToStart <= 0 && secondsToEnd > 0

        func timer(seconds: Int) -> Observable<Void> {
            seconds > 0 ? Observable<Int>.timer(.seconds(seconds), scheduler: scheduler).void() : .empty()
        }

        self.isInProgress = timer(seconds: secondsToStart).map(true)
            .concat(
                Observable.deferred {
                    timer(seconds: distance(to: event.end)).map(false)
                }
            )
            .startWith(isAlreadyInProgress)
            .share(replay: 1)
    }

    func makeContextMenuViewModel() -> (any ContextMenuViewModel)? {

        ContextMenuFactory.makeViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: .details,
            callback: callback
        )
    }
}

private func parseNotesMeetingInfo(from notes: String?) -> (notes: String?, meetingInfo: String?) {

    let marker = "-::~:~::~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~:~::~:~::-"

    guard
        var notes,
        let startRange = notes.range(of: marker),
        let endRange = notes.range(of: marker, range: startRange.upperBound..<notes.endIndex)
    else {
        return (notes, nil) // Return input unchanged if markers not found
    }

    let meetingInfo = notes[startRange.upperBound..<endRange.lowerBound]
        .trimmingCharacters(in: .whitespacesAndNewlines)

    // Remove the markers and content
    notes.removeSubrange(startRange.lowerBound..<endRange.upperBound)
    notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

    return (notes, meetingInfo)
}
