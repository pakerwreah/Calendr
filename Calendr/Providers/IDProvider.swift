//
//  IDProvider.swift
//  Calendr
//
//  Created by Paker on 29/10/2025.
//

protocol IDProviding {
    associatedtype ID: Hashable
    func next() -> ID
}

class UUIDProvider: IDProviding {
    func next() -> UUID { .init() }
}

class IntIDProvider: IDProviding {

    private var current = 1

    init(initial: Int = 1) {
        self.current = initial
    }

    func next() -> Int {
        defer { current += 1 }
        return current
    }
}
