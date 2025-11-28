//
//  MockLocalStorage.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import Foundation

#if DEBUG

class InMemoryStorage: NSObject, LocalStorage {
    private var storage: [String: Any] = [:]
    private var registeredDefaults: [String: Any] = [:]

    func reset() {
        storage.removeAll()
    }

    func register(defaults registrationDictionary: [String : Any]) {
        for (key, value) in registrationDictionary {
            registeredDefaults[key] = value
        }
    }

    override func value(forKey name: String) -> Any? {
        object(forKey: name)
    }

    func set(_ value: Any?, forKey name: String) {
        willChangeValue(forKey: name)
        storage[name] = value
        didChangeValue(forKey: name)
    }

    func removeObject(forKey name: String) {
        willChangeValue(forKey: name)
        storage.removeValue(forKey: name)
        didChangeValue(forKey: name)
    }

    func object(forKey name: String) -> Any? {
        storage[name] ?? registeredDefaults[name]
    }

    func data(forKey name: String) -> Data? {
        object(forKey: name) as? Data
    }

    func array(forKey name: String) -> [Any]? {
        object(forKey: name) as? [Any]
    }

    func dictionary(forKey name: String) -> [String : Any]? {
        object(forKey: name) as? [String : Any]
    }

    func string(forKey name: String) -> String? {
        object(forKey: name) as? String
    }

    func stringArray(forKey name: String) -> [String]? {
        object(forKey: name) as? [String]
    }

    func bool(forKey name: String) -> Bool {
        object(forKey: name) as? Bool ?? false
    }

    func double(forKey name: String) -> Double {
        (object(forKey: name) as? NSNumber)?.doubleValue ?? 0
    }

    func integer(forKey name: String) -> Int {
        (object(forKey: name) as? NSNumber)?.intValue ?? 0
    }
}

class MockLocalStorageProvider: LocalStorageProvider {

    private let memory: InMemoryStorage

    required init() {
        memory = InMemoryStorage()
        super.init(storage: memory)
    }

    func reset() {
        memory.reset()
    }
}

#endif
