//
//  Scaling.swift
//  Calendr
//
//  Created by Paker on 23/09/2024.
//

import Foundation
import RxSwift

enum Scaling {
    static let observable = LocalStorageProvider.shared.rx.observe(\.textScaling).share(replay: 1)

    static var current: Double {
        var value: Double = 1
        observable.bind { value = $0 }.dispose()
        return value
    }
}
