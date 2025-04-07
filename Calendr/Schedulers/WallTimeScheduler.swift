//
//  WallTimeScheduler.swift
//  Calendr
//
//  Created by Paker on 03/03/2021.
//

import Foundation
import RxSwift

/**
 Wrapper around `MainScheduler` that uses `DispatchWallTime` to schedule work.
 The purpose of this scheduler is to schedule work using the `wallDeadline` method,
 which hopefully guarantees that it will trigger with no delay after the computer wakes from sleep.
*/
class WallTimeScheduler: SchedulerType {

    static let instance = WallTimeScheduler()

    var now: RxTime { Date() }

    func scheduleRelative<StateType>(_ state: StateType, dueTime: RxTimeInterval,
                                     action: @escaping (StateType) -> Disposable) -> Disposable {

        let deadline = DispatchWallTime.now() + dueTime

        let compositeDisposable = CompositeDisposable()

        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: .main)
        timer.schedule(wallDeadline: deadline, leeway: .nanoseconds(0))

        let cancelTimer = Disposables.create {
            timer.cancel()
        }

        timer.setEventHandler(handler: {
            if compositeDisposable.isDisposed {
                return
            }
            _ = compositeDisposable.insert(action(state))
            cancelTimer.dispose()
        })
        timer.resume()

        _ = compositeDisposable.insert(cancelTimer)

        return compositeDisposable
    }

    func schedule<StateType>(_ state: StateType, action: @escaping (StateType) -> Disposable) -> Disposable {
        MainScheduler.instance.schedule(state, action: action)
    }
}
