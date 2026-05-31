//
//  EventFullScreenViewModel.swift
//  Calendr
//
//  Created by Paker on 30/05/2026.
//

import SwiftUI
import RxSwift

@Observation.Observable
class EventFullScreenViewModel {
    let title: String
    let duration: String
    let link: EventLink?

    var isDismissLocked = true

    let onDismiss: Observable<Void>
    private let onDismissObserver: AnyObserver<Void>

    private let onSkip: () -> Void

    private let workspace: WorkspaceServiceProviding

    func performClose() {
        if !isDismissLocked {
            onDismissObserver.onNext(())
        }
    }

    func join() {
        if !isDismissLocked, let link {
            workspace.open(link.url)
            performClose()
        }
    }

    func skip() {
        if !isDismissLocked {
            onSkip()
            performClose()
        }
    }

    func onAppear() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isDismissLocked = false
        }
    }

    init(
        event: EventModel,
        dateProvider: DateProviding,
        forceLocalTimeZone: Bool,
        workspace: WorkspaceServiceProviding,
        onSkip: @escaping () -> Void
    ) {
        self.workspace = workspace
        self.onSkip = onSkip

        self.title = event.title

        self.duration = EventUtils.duration(
            for: event,
            using: dateProvider,
            dateStyle: .none,
            timeStyle: .short,
            forceLocalTimeZone: forceLocalTimeZone
        )

        self.link = event.detectLink(using: workspace)

        (onDismiss, onDismissObserver) = PublishSubject.pipe()
    }
}
