//
//  EventFullScreenViewModel.swift
//  Calendr
//
//  Created by Paker on 30/05/2026.
//

import Observation
import RxSwift

@Observation.Observable
class EventFullScreenViewModel {
    let title: String
    let duration: String
    let link: EventLink?

    var isDismissLocked = true

    var transparencyLevel: Int {
        didSet {
            localStorage.fullScreenEventTransparencyLevel = transparencyLevel
        }
    }

    var material: Material {
        [
            .ultraThick,
            .thick,
            .regular,
            .thin,
            .ultraThin
        ][clamped: transparencyLevel]!
    }

    private let disposeBag = DisposeBag()

    private let onAppearSubject = PublishSubject<Void>()

    let onDismiss: Observable<Void>
    private let onDismissObserver: AnyObserver<Void>

    private let localStorage: LocalStorageProvider
    private let workspace: WorkspaceServiceProviding
    private let scheduler: SchedulerType

    private let onSkip: () -> Void

    func performClose() {
        if !isDismissLocked {
            onDismissObserver.onNext(())
        }
    }

    func join() {
        if !isDismissLocked, let link {
            workspace.open(link)
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
        onAppearSubject.onNext(())
    }

    init(
        event: EventModel,
        dateProvider: DateProviding,
        forceLocalTimeZone: Bool,
        localStorage: LocalStorageProvider,
        workspace: WorkspaceServiceProviding,
        scheduler: SchedulerType,
        onSkip: @escaping () -> Void
    ) {
        self.localStorage = localStorage
        self.workspace = workspace
        self.scheduler = scheduler
        self.onSkip = onSkip

        self.title = event.title

        self.duration = EventUtils.duration(
            for: event,
            using: dateProvider,
            preferredDateStyle: .none,
            preferredTimeStyle: .short,
            forceLocalTimeZone: forceLocalTimeZone
        )

        self.link = event.detectLink(using: workspace)

        self.transparencyLevel = localStorage.fullScreenEventTransparencyLevel

        (onDismiss, onDismissObserver) = PublishSubject.pipe()

        onAppearSubject
            .delay(.milliseconds(1500), scheduler: scheduler)
            .take(1)
            .bind { [weak self] in
                self?.isDismissLocked = false
            }
            .disposed(by: disposeBag)
    }
}
