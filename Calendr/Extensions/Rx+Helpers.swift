//
//  Rx+Helpers.swift
//  Calendr
//
//  Created by Paker on 27/12/20.
//

import RxSwift

extension ObservableType {
    public func toVoid() -> Observable<Void> {
        return map { _ in () }
    }
}
