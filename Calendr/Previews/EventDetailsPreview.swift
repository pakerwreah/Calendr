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
    static let workspace = WorkspaceServiceProvider()
    static let settings = MockPopoverSettings()
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
                    type: .event(.accepted),
                    participants: .mock
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false)
            )
        )
        vc.view.width(equalTo: 300)
        vc.view.heightAnchor.constraint(lessThanOrEqualToConstant: 500).activate()
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
                workspace: workspace,
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false)
            )
        )
        vc.view.width(equalTo: 300)
        vc.view.heightAnchor.constraint(lessThanOrEqualToConstant: 500).activate()
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
                workspace: workspace,
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false)
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
                    type: .reminder
                ),
                dateProvider: dateProvider,
                calendarService: calendarService,
                workspace: workspace,
                settings: settings,
                isShowingObserver: .dummy(),
                isInProgress: .just(false)
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
        .init(name: "Liam", status: .declined, isOrganizer: false, isCurrentUser: false),
        .init(name: "Olivia", status: .pending, isOrganizer: false, isCurrentUser: false),
        .init(name: "Noah", status: .pending, isOrganizer: false, isCurrentUser: false),
        .init(name: "Emma", status: .accepted, isOrganizer: true, isCurrentUser: false),
        .init(name: "Carlos", status: .maybe, isOrganizer: false, isCurrentUser: true),
        .init(name: "Charlotte", status: .accepted, isOrganizer: false, isCurrentUser: false),
        .init(name: "Elijah", status: .accepted, isOrganizer: false, isCurrentUser: false),
        .init(name: "Nelson", status: .declined, isOrganizer: false, isCurrentUser: false),
        .init(name: "Brian", status: .accepted, isOrganizer: false, isCurrentUser: false),
        .init(name: "Oliver", status: .accepted, isOrganizer: false, isCurrentUser: false),
        .init(name: "Lucas", status: .accepted, isOrganizer: false, isCurrentUser: false),
        .init(name: "Jean", status: .maybe, isOrganizer: false, isCurrentUser: false)
    ]
}

#endif
