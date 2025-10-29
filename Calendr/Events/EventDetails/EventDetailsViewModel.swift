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
        let isDefault: Bool
    }

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
    let browserOptions: [BrowserOption]
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

    let selectedBrowserObserver: AnyObserver<Int>
    let selectedBrowserIndex: Observable<Int>

    private let event: EventModel
    private let dateProvider: DateProviding
    private let calendarService: CalendarServiceProviding
    private let workspace: WorkspaceServiceProviding

    private let callback: AnyObserver<ContextCallbackAction>

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
        localStorage: LocalStorageProvider,
        settings: EventSettings,
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

        showSkip = source ~= .menubar

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

            let forceLocalTimeZone = settings.forceLocalTimeZone.lastValue() ?? false
            let timeZone = event.isMeeting || forceLocalTimeZone ? nil : event.timeZone

            duration = EventUtils.duration(
                from: event.start,
                to: end,
                timeZone: timeZone,
                formatter: formatter
            )
        }

        let closeSubject = PublishSubject<Never>()

        close = closeSubject.asCompletable()

        self.callback = callback.mapObserver {
            closeSubject.onCompleted()
            return $0
        }

        skipTapped = self.callback.mapObserver { _ in
            // handled by NextEventViewModel
            return .event(.skip)
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

            if let pattern = localStorage.showMapBlacklistRegex {
                do {
                    return try Regex(pattern).wholeMatch(in: location) == nil
                } catch {
                    print(error.localizedDescription)
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

        let defaultBrowserURL = workspace.urlForDefaultBrowserApplication()

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
                icon: icon,
                name: String(name.dropLast(4)),
                url: url,
                isDefault: url == defaultBrowserURL
            )
        }
        .sorted {
            if $0.isDefault && !$1.isDefault {
                return true // $0 is default, so it should come first
            }
            if !$0.isDefault && $1.isDefault {
                return false // $1 is default, so it should come first
            }
            return $0.name < $1.name // Otherwise, sort by name
        }

        selectedBrowserIndex = localStorage.rx.observe(\.defaultBrowserPerCalendar)
            .map {
                let url = if let path = $0[event.calendar.id], let pathUrl = URL(string: path) {
                    pathUrl
                } else {
                    defaultBrowserURL
                }
                return browserOptions.firstIndex { $0.url == url } ?? 0
            }

        selectedBrowserObserver = localStorage.rx.observer(for: \.defaultBrowserPerCalendar)
            .mapObserver { index in
                var mapping = localStorage.defaultBrowserPerCalendar
                if index > 0 {
                    mapping[event.calendar.id] = browserOptions[index].url.absoluteString
                } else {
                    mapping.removeValue(forKey: event.calendar.id)
                }
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
