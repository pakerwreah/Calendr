//
//  LocalStorageProvider.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import RxSwift
import RxCocoa

protocol LocalStorage: NSObject {

    func register(defaults: [String : Any])

    func set(_ value: Any?, forKey: String)

    func removeObject(forKey: String)

    func object(forKey: String) -> Any?

    func data(forKey: String) -> Data?

    func array(forKey: String) -> [Any]?

    func dictionary(forKey: String) -> [String: Any]?

    func string(forKey: String) -> String?

    func stringArray(forKey: String) -> [String]?

    func bool(forKey: String) -> Bool

    func double(forKey: String) -> Double

    func integer(forKey: String) -> Int
}

/// This wrapper is necessary because we need an `NSObject` to extend with `@objc dynamic properties`
/// If we add this constraint directly to the protocol, we have to deal with "existential types" which are absolute nightmares
class LocalStorageProvider: NSObject, LocalStorage {

    fileprivate let storage: LocalStorage

    init(storage: LocalStorage) {
        self.storage = storage
    }

    func register(defaults: [String : Any]) {
        storage.register(defaults: defaults)
    }

    override func value(forKey name: String) -> Any? {
        object(forKey: name)
    }

    func set(_ value: Any?, forKey name: String) {
        willChangeValue(forKey: name)
        storage.set(value, forKey: name)
        didChangeValue(forKey: name)
    }

    func removeObject(forKey name: String) {
        willChangeValue(forKey: name)
        storage.removeObject(forKey: name)
        didChangeValue(forKey: name)
    }

    func object(forKey name: String) -> Any? {
        storage.object(forKey: name)
    }

    func data(forKey name: String) -> Data? {
        storage.data(forKey: name)
    }

    func array(forKey name: String) -> [Any]? {
        storage.array(forKey: name)
    }

    func dictionary(forKey name: String) -> [String: Any]? {
        storage.dictionary(forKey: name)
    }

    func string(forKey name: String) -> String? {
        storage.string(forKey: name)
    }

    func stringArray(forKey name: String) -> [String]? {
        storage.stringArray(forKey: name)
    }

    func bool(forKey name: String) -> Bool {
        storage.bool(forKey: name)
    }

    func double(forKey name: String) -> Double {
        storage.double(forKey: name)
    }

    func integer(forKey name: String) -> Int {
        storage.integer(forKey: name)
    }
}

extension UserDefaults: LocalStorage {}

private let _shared = LocalStorageProvider(
    storage: {
        #if DEBUG
        guard !BuildConfig.isUITesting, !BuildConfig.isPreview else {
            return InMemoryStorage()
        }
        #endif
        return UserDefaults.standard
    }()
)

extension LocalStorageProvider {

    static var shared: LocalStorageProvider {

        guard !BuildConfig.isTesting else {
            fatalError("Use memory storage in tests")
        }

        return _shared
    }

    func withDefaults() -> Self {
        registerDefaultPrefs(in: self)
        return self
    }
}

extension Reactive where Base: LocalStorageProvider {

    func observe<Element: KVORepresentable>(_ type: Element.Type, _ keyPath: String, options: KeyValueObservingOptions = [.new, .initial]) -> Observable<Element?> {

        (base.storage as NSObject).rx.observe(type, keyPath, options: options)
    }
}
