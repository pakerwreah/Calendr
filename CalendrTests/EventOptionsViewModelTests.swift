//
//  EventOptionsViewModelTests.swift
//  CalendrTests
//
//  Created by Paker on 18/02/23.
//

import Foundation
import RxSwift
import Testing
@testable import Calendr

class EventOptionsViewModelTests {

    let disposeBag = DisposeBag()

    let dateProvider = MockDateProvider()
    let calendarService = MockCalendarServiceProvider()
    lazy var workspace = MockWorkspaceServiceProvider(dateProvider: dateProvider)

    @Test func testOptions_withPendingInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.pending)), source: .details)
        #expect(viewModel.items == [
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    @Test func testOptions_withAcceptedInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.accepted)), source: .details)
        #expect(viewModel.items == [
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    @Test func testOptions_withMaybeInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.maybe)), source: .details)
        #expect(viewModel.items == [
            .action(.status(.accept)),
            .action(.status(.decline))
        ])
    }

    @Test func testOptions_withDeclinedInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.declined)), source: .details)
        #expect(viewModel.items == [
            .action(.status(.accept)),
            .action(.status(.maybe))
        ])
    }

    @Test func testStatusChanged_shouldChangeStatus() {

        var status: EventStatus?
        var callback: EventAction?

        let viewModel = mock(event: .make(type: .event(.pending)), source: .details) {
            callback = $0
        }

        calendarService.spyChangeEventStatusObservable
            .bind { status = $0 }
            .disposed(by: disposeBag)

        let action: EventAction = .status(.accept)

        viewModel.triggerAction(action)

        #expect(status == .accepted)
        #expect(callback == action)
    }

    @Test func testOptions_fromList_withUnknownInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.unknown)), source: .calendar)
        #expect(viewModel.items == [.action(.open), .separator, .action(.delete)])
    }

    @Test func testOptions_fromList_withUnknownInvitationStatus_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.unknown)), source: .calendar)
        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false)),
            .separator,
            .action(.delete)
        ])
    }

    @Test func testOptions_fromList() {

        let viewModel = mock(event: .make(type: .event(.pending)), source: .calendar)
        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline)),
            .separator,
            .action(.delete)
        ])
    }

    @Test func testOptions_fromList_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.pending)), source: .calendar)
        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false)),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline)),
            .separator,
            .action(.delete)
        ])
    }

    @Test func testOptions_fromMenuBar_withUnknownInvitationStatus() {

        let viewModel = mock(event: .make(type: .event(.unknown)), source: .menubar)
        #expect(viewModel.items == [.action(.open), .separator, .action(.skip)])
    }

    @Test func testOptions_fromMenuBar_withUnknownInvitationStatus_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.unknown)), source: .menubar)
        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false)),
            .separator,
            .action(.skip)
        ])
    }

    @Test func testOptions_fromMenuBar() {

        let viewModel = mock(event: .make(type: .event(.pending)), source: .menubar)
        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.skip),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    @Test func testOptions_fromMenuBar_withLink() {

        let viewModel = mock(event: .make(url: EventLink.zoomLink.url, type: .event(.pending)), source: .menubar)
        #expect(viewModel.items == [
            .action(.open),
            .separator,
            .action(.link(.zoomLink, isInProgress: false)),
            .separator,
            .action(.skip),
            .separator,
            .action(.status(.accept)),
            .action(.status(.maybe)),
            .action(.status(.decline))
        ])
    }

    @Test func testOptions_fromList_withReadOnlyCalendar_doesNotIncludeDelete() {

        let event = EventModel.make(
            type: .event(.unknown),
            calendar: .make(allowsContentModifications: false)
        )

        let viewModel = mock(event: event, source: .calendar)

        #expect(viewModel.items == [.action(.open)])
    }

    @Test func testOptions_fromList_withBirthday_doesNotIncludeDelete() {

        let viewModel = mock(event: .make(type: .birthday), source: .calendar)

        #expect(viewModel.items == [.action(.open)])
    }

    @Test func testDeleteStandaloneEvent_deletesOnlyThatEventWithoutConfirmation() {
        let start: Date = .make(year: 2026, month: 8, day: 9, hour: 14)
        let confirmation = MockEventDeletionConfirmation(scope: .futureEvents)
        var deletedEvent: DeleteEventArgs?

        calendarService.spyDeleteEventObservable
            .bind { deletedEvent = $0 }
            .disposed(by: disposeBag)

        let viewModel = mock(
            event: .make(id: "event-id", start: start, type: .event(.unknown)),
            source: .calendar,
            deletionConfirmation: confirmation
        )

        viewModel.triggerAction(.delete)

        #expect(confirmation.callCount == 0)
        #expect(deletedEvent?.id == "event-id")
        #expect(deletedEvent?.date == start)
        #expect(deletedEvent?.scope == .thisEvent)
    }

    @Test func testDeleteRecurringEvent_withThisEventConfirmation() {
        let start: Date = .make(year: 2026, month: 8, day: 9, hour: 14)
        let confirmation = MockEventDeletionConfirmation(scope: .thisEvent)
        var deletedEvent: DeleteEventArgs?

        calendarService.spyDeleteEventObservable
            .bind { deletedEvent = $0 }
            .disposed(by: disposeBag)

        let viewModel = mock(
            event: .make(id: "event-id", start: start, type: .event(.unknown), hasRecurrenceRules: true),
            source: .calendar,
            deletionConfirmation: confirmation
        )

        viewModel.triggerAction(.delete)

        #expect(confirmation.callCount == 1)
        #expect(deletedEvent?.scope == .thisEvent)
    }

    @Test func testDeleteRecurringEvent_withFutureEventsConfirmation() {
        let confirmation = MockEventDeletionConfirmation(scope: .futureEvents)
        var deletedEvent: DeleteEventArgs?

        calendarService.spyDeleteEventObservable
            .bind { deletedEvent = $0 }
            .disposed(by: disposeBag)

        let viewModel = mock(
            event: .make(type: .event(.unknown), hasRecurrenceRules: true),
            source: .calendar,
            deletionConfirmation: confirmation
        )

        viewModel.triggerAction(.delete)

        #expect(confirmation.callCount == 1)
        #expect(deletedEvent?.scope == .futureEvents)
    }

    @Test func testDeleteRecurringEvent_withCancelledConfirmation_doesNotDelete() {
        let confirmation = MockEventDeletionConfirmation(scope: nil)
        var deletedEvent: DeleteEventArgs?

        calendarService.spyDeleteEventObservable
            .bind { deletedEvent = $0 }
            .disposed(by: disposeBag)

        let viewModel = mock(
            event: .make(type: .event(.unknown), hasRecurrenceRules: true),
            source: .calendar,
            deletionConfirmation: confirmation
        )

        viewModel.triggerAction(.delete)

        #expect(confirmation.callCount == 1)
        #expect(deletedEvent == nil)
    }

    @Test func testOptions_withOpenTriggered() async {
        let openExpectation = expectation(description: "Open")

        let viewModel = mock(event: .make(id: "12345", type: .event(.pending)), source: .calendar)

        workspace.didOpenEvent = { event in
            #expect(event.id == "12345")
            openExpectation.fulfill()
        }

        viewModel.triggerAction(.open)
        await fulfillment(of: [openExpectation])
    }

    @Test func testEventLinkAction_isMeeting() {
        #expect(EventAction.link(.zoomLink, isInProgress: false).title == Strings.Event.Action.join)

        #expect(EventAction.link(.zoomLink, isInProgress: false).icon == Icons.Event.video)

        #expect(
            EventAction.link(.zoomLink, isInProgress: true).icon?.tiffRepresentation ==
            Icons.Event.video_fill.with(color: .controlAccentColor).tiffRepresentation
        )
    }

    @Test func testEventLinkAction_isGenericLink() {
        #expect(EventAction.link(.genericLink, isInProgress: false).title == "google.com")

        #expect(EventAction.link(.genericLink, isInProgress: false).icon == Icons.Event.link)

        #expect(
            EventAction.link(.genericLink, isInProgress: true).icon?.tiffRepresentation ==
            Icons.Event.link.with(color: .controlAccentColor).tiffRepresentation
        )
    }

    @Test func testDeleteAction() {
        #expect(EventAction.delete.title == Strings.Event.Action.delete)
        #expect(EventAction.delete.icon == Icons.Event.delete)
    }

    func mock(
        event: EventModel,
        source: ContextMenuSource,
        callback: @escaping (EventAction?) -> Void = { _ in },
        deletionConfirmation: EventDeletionConfirming = MockEventDeletionConfirmation()
    ) -> EventOptionsViewModel {

        EventOptionsViewModel(
            event: event,
            dateProvider: dateProvider,
            calendarService: calendarService,
            workspace: workspace,
            source: source,
            callback: .init { callback($0.element) },
            deletionConfirmation: deletionConfirmation
        )!
    }
}

private final class MockEventDeletionConfirmation: EventDeletionConfirming {

    private let scope: EventDeletionScope?
    private(set) var callCount = 0

    init(scope: EventDeletionScope? = nil) {
        self.scope = scope
    }

    func confirmDeletion() -> EventDeletionScope? {
        callCount += 1
        return scope
    }
}

private extension EventLink {

    static let zoomLink: Self = .init(
        url: URL(string: "https://zoom.us/j/9999999999")!,
        original: URL(string: "https://zoom.us/j/9999999999")!,
        isMeeting: true,
        calendarId: ""
    )

    static let genericLink: Self = .init(
        url: URL(string: "https://google.com/something")!,
        original: URL(string: "https://google.com/something")!,
        isMeeting: false,
        calendarId: ""
    )
}
