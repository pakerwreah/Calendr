//
//  UserDefaults+Rx.swift
//  Calendr
//
//  Created by Paker on 30/09/22.
//

import Foundation
import RxSwift

extension Reactive where Base: UserDefaults {

    func observer<T>(for keyPath: ReferenceWritableKeyPath<Base, T>) -> AnyObserver<T> {
        .init {
            guard let value = $0.element else { return }
            base[keyPath: keyPath] = value
        }
    }

    func toggleObserver<T: Equatable>(for keyPath: ReferenceWritableKeyPath<Base, [T]>) -> AnyObserver<T> {
        .init {
            guard let toggled = $0.element else { return }
            let values = base[keyPath: keyPath]
            base[keyPath: keyPath] = values.contains(toggled)
                ? values.filter { $0 != toggled }
                : values + [toggled]
        }
    }
}
