//
//  SwiftUI.swift
//  Calendr
//
//  Created by Paker on 24/09/2025.
//

import RxSwift
import SwiftUI

extension ObservableObject {

    func asStateObject() -> StateObject<Self> {
        StateObject(wrappedValue: self)
    }
}

extension View {

    func nsView() -> NSView {
        NSHostingView(rootView: self)
    }
}

extension ObservableType {

    // Bridge RxSwift Observable to a SwiftUI ObservableObject property using a key path.
    // Usage: observable.bind(to: object, \.property)
    func bind<Object: AnyObject>(
        to object: Object,
        _ keyPath: ReferenceWritableKeyPath<Object, Element>
    ) -> Disposable {

        subscribe(onNext: { [weak object] value in
            object?[keyPath: keyPath] = value
        })
    }
}
