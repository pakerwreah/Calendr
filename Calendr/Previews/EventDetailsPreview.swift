//
//  EventDetailsPreview.swift
//  Calendr
//
//  Created by Paker on 28/05/22.
//

#if DEBUG

import SwiftUI
import RxSwift

struct EventDetailsPreview: PreviewProvider {

    static let dateProvider = MockDateProvider()
    static let calendarService = MockCalendarServiceProvider()
    static let geocoder = MockGeocodeServiceProvider()
    static let weatherService = MockWeatherServiceProvider()
    static let workspace = MockWorkspaceServiceProvider()
    static let settings = MockEventDetailsSettings()
    static var vcs: [NSViewController] = []

    static func makeMeeting() -> some View {
        let vc = EventDetailsViewController(
            viewModel: EventDetailsViewModel(
                event: .make(
                    start: dateProvider.now,
                    end: dateProvider.now + 999,
                    title: "Test with a very long event name and some more extra text",
                    location: "Brasil",
                    notes: Strings.longText,
                    url: .init(string: "https://zoom.us/j/9999999999"),
                    type: .event(.accepted),
                    participants: .mock
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                geocoder: geocoder,
                weatherService: weatherService,
                workspace: workspace,
                userDefaults: .init(),
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false),
                source: .menubar,
                callback: .dummy()
            )
        )
        vc.view.width(equalTo: 300)
        vc.view.height(lessThanOrEqualTo: 500)
        vcs.append(vc)

        return vc.view.preview().fixedSize()
    }

    static func makeEvent() -> some View {
        let vc = EventDetailsViewController(
            viewModel: EventDetailsViewModel(
                event: .make(
                    start: dateProvider.now,
                    end: dateProvider.now,
                    title: "Test event",
                    location: "Brasil",
                    notes: Strings.shortText,
                    type: .event(.unknown)
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                geocoder: geocoder,
                weatherService: weatherService,
                workspace: workspace,
                userDefaults: .init(),
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false),
                source: .menubar,
                callback: .dummy()
            )
        )
        vc.view.width(equalTo: 300)
        vc.view.height(lessThanOrEqualTo: 500)
        vcs.append(vc)

        return vc.view.preview().fixedSize()
    }

    static func makeBirthday() -> some View {
        let vc = EventDetailsViewController(
            viewModel: EventDetailsViewModel(
                event: .make(
                    title: "Someones birthday",
                    type: .birthday
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                geocoder: geocoder,
                weatherService: weatherService,
                workspace: workspace,
                userDefaults: .init(),
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false),
                source: .menubar,
                callback: .dummy()
            )
        )
        vc.view.width(equalTo: 250)
        vcs.append(vc)

        return vc.view.preview().fixedSize()
    }

    static func makeReminder() -> some View {
        let vc = EventDetailsViewController(
            viewModel: EventDetailsViewModel(
                event: .make(
                    title: "Some reminder",
                    type: .reminder(completed: false)
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                geocoder: geocoder,
                weatherService: weatherService,
                workspace: workspace,
                userDefaults: .init(),
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false),
                source: .menubar,
                callback: .dummy()
            )
        )
        vc.view.width(equalTo: 250)
        vcs.append(vc)

        return vc.view.preview().fixedSize()
    }

    static var previews: some View {
        makeMeeting()
        makeEvent()
        makeBirthday()
        makeReminder()
    }
}

private extension Strings {

    static let shortText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."

    static let longText =
    """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer non placerat sapien, sed cursus mi. Sed ut tempus orci. Nunc imperdiet et diam sed fermentum. Maecenas molestie ultrices aliquam. Morbi erat odio, efficitur vitae eleifend ut, vehicula in leo. Vivamus at orci ac mi dapibus pulvinar sit amet sit amet felis. Sed convallis nunc in neque iaculis, eu rhoncus erat rutrum.
    """
}

private extension Array where Element == Participant {

    static let mock: Self = [
        .make(name: "Liam", status: .declined),
        .make(name: "Olivia", status: .pending),
        .make(name: "Noah", status: .pending),
        .make(name: "Emma", status: .accepted, isOrganizer: true),
        .make(name: "Carlos", status: .maybe, isCurrentUser: true),
        .make(name: "Charlotte", status: .accepted),
        .make(name: "Elijah", status: .accepted),
        .make(name: "Nelson", status: .declined),
        .make(name: "Brian", status: .accepted),
        .make(name: "Oliver", status: .accepted),
        .make(name: "Lucas", status: .accepted),
        .make(name: "Jean", status: .maybe)
    ]
}

#endif
