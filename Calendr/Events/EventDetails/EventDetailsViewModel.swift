//
//  EventDetailsViewModel.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Cocoa
import RxSwift

enum EventDetailsSource {
    case list
    case menubar
}

class EventDetailsViewModel {

    struct BrowserOption {
        let icon: NSImage
        let name: String
        let url: URL
    }

    let type: EventType
    let status: EventStatus
    let title: String
    let duration: String
    let url: String
    let location: String
    let notes: String
    let participants: [Participant]
    let link: EventLink?
    let settings: EventDetailsSettings
    let showSkip: Bool
    let browserOptions: [BrowserOption]
    let optimisticLoadTime: DispatchTimeInterval

    let canShowMap = BehaviorSubject<Bool>(value: false)
    let coordinates: Maybe<Coordinates>
    let weather: Maybe<(Weather, isAllDay: Bool)>
    let isInProgress: Observable<Bool>
    let close: Completable

    let linkTapped: AnyObserver<Void>
    let skipTapped: AnyObserver<Void>
    let openMaps: AnyObserver<Coordinates>
    let isShowingObserver: AnyObserver<Bool>

    let selectedBrowserObserver: AnyObserver<Int>
    let selectedBrowserIndex: Observable<Int>

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let workspace: WorkspaceServiceProviding

    private let callback: AnyObserver<ContextCallbackAction>
    private let action = PublishSubject<ContextCallbackAction>()

    private let disposeBag = DisposeBag()

    var accessibilityIdentifier: String? {
        switch type {
        case .event:
            return Accessibility.EventDetails.view
        case .reminder:
            return Accessibility.ReminderDetails.view
        case .birthday:
            return nil
        }
    }

    init(
        event: EventModel,
        dateProvider: DateProviding,
        calendarService: CalendarServiceProviding,
        geocoder: GeocodeServiceProviding,
        weatherService: WeatherServiceProviding,
        workspace: WorkspaceServiceProviding,
        userDefaults: UserDefaults,
        settings: EventDetailsSettings,
        isShowingObserver: AnyObserver<Bool>,
        isInProgress: Observable<Bool>,
        source: EventDetailsSource,
        callback: AnyObserver<ContextCallbackAction>
    ) {
        self.event = event
        self.dateProvider = dateProvider
        self.calendarService = calendarService
        self.settings = settings
        self.isShowingObserver = isShowingObserver
        self.isInProgress = isInProgress
        self.workspace = workspace

        type = event.type
        status = event.status
        title = event.title
        link = event.detectLink(using: workspace)
        url = type.isBirthday ? "" : link.map { $0.isNative ? "" : $0.original.absoluteString } ?? ""
        location = event.location ?? ""
        notes = event.notes ?? ""
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

        showSkip = !type.isReminder && source ~= .menubar

        let formatter = DateIntervalFormatter()
        formatter.dateStyle = .medium
        formatter.calendar = dateProvider.calendar

        if event.isAllDay {
            formatter.timeStyle = .none
            duration = formatter.string(from: event.start, to: event.end)
        } else {
            formatter.timeStyle = .short

            let range = event.range(using: dateProvider)

            let end: Date

            if type.isReminder {
                end = event.start
            }
            else if range.isSingleDay && range.endsMidnight {
                end = dateProvider.calendar.startOfDay(for: event.start)
            }
            else {
                end = event.end
            }

            duration = EventUtils.duration(
                from: event.start,
                to: end,
                timeZone: event.timeZone,
                formatter: formatter,
                isMeeting: event.isMeeting
            )
        }

        let closeSubject = PublishSubject<Never>()

        close = closeSubject.asCompletable()

        self.callback = callback.mapObserver {
            closeSubject.onCompleted()
            return $0
        }

        skipTapped = self.callback.mapObserver { _ in
            return .event(.skip)
        }

        let showMap = settings.showMap.take(1)

        showMap.bind(to: canShowMap).disposed(by: disposeBag)

        coordinates = showMap.asSingle().flatMapMaybe { showMap in
            guard showMap, let address = event.location, !address.isEmpty else {
                return .empty()
            }
            if let coordinates = event.coordinates {
                return .just(coordinates)
            }
            return Maybe.create { observer in
                Task {
                    guard let coordinates = await geocoder.geocodeAddressString(address) else {
                        return observer(.completed)
                    }
                    observer(.success(coordinates))
                }
                return Disposables.create()
            }
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

        optimisticLoadTime = .milliseconds(canShowMap.value && !event.location.isNilOrEmpty ? 50 : 0)

        let browserOptions: [BrowserOption] = workspace.urlsForBrowsersApplications().compactMap { url in
            guard
                url.lastPathComponent.hasSuffix(".app"),
                url.deletingLastPathComponent().lastPathComponent == "Applications",
                let res = try? url.resourceValues(forKeys: [.nameKey, .effectiveIconKey]),
                let icon = res.effectiveIcon as? NSImage,
                let name = res.name
            else {
                return nil
            }
            return .init(
                icon: icon.with(size: .init(width: 16, height: 16)),
                name: String(name.dropLast(4)),
                url: url
            )
        }
        .sorted(by: \.name)

        selectedBrowserIndex = userDefaults.rx.observe(\.defaultBrowserPerCalendar)
            .map {
                let url = if let path = $0[event.calendar.id], let pathUrl = URL(string: path) {
                    pathUrl
                } else {
                    workspace.urlForDefaultBrowserApplication()
                }
                return browserOptions.firstIndex { $0.url == url } ?? 0
            }

        selectedBrowserObserver = userDefaults.rx.observer(for: \.defaultBrowserPerCalendar)
            .mapObserver { index in
                print("selecting", index)
                var mapping = userDefaults.defaultBrowserPerCalendar
                mapping[event.calendar.id] = browserOptions[index].url.absoluteString
                return mapping
            }

        self.browserOptions = browserOptions
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
