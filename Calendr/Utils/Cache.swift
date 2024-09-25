//
//  Cache.swift
//  Calendr
//
//  Created by Paker on 07/09/2024.
//

import Foundation

protocol Cache: AnyObject {
    associatedtype Key: Hashable
    associatedtype Value
    
    func get(_ key: Key) -> Value?
    func set(_ key: Key, _ value: Value)
    func remove(_ key: Key)
}

// Least Recently Used
class LRUCache<Key: Hashable, Value>: Cache {
    private var cache: [Key: Value] = [:]
    private var order: [Key] = []
    private let capacity: Int
    private let locker = NSLock()

    init(capacity: Int) {
        self.capacity = capacity
    }

    func get(_ key: Key) -> Value? {
        locker.withLock { unsafe_get(key) }
    }

    func set(_ key: Key, _ value: Value) {
        locker.withLock { unsafe_set(key, value) }
    }

    func remove(_ key: Key) {
        locker.withLock { unsafe_remove(key) }
    }

    private func unsafe_get(_ key: Key) -> Value? {
        if let value = cache[key] {
            // Move the key to the end to mark it as recently used
            if let index = order.firstIndex(of: key) {
                order.remove(at: index)
            }
            order.append(key)
            return value
        }
        return nil
    }

    private func unsafe_set(_ key: Key, _ value: Value) {
        if cache[key] != nil {
            // If the key already exists, update the value and move it to the end
            if let index = order.firstIndex(of: key) {
                order.remove(at: index)
            }
        } else if cache.count >= capacity {
            // If the cache is at capacity, remove the least recently used item
            let leastUsedKey = order.removeFirst()
            cache.removeValue(forKey: leastUsedKey)
        }
        order.append(key)
        cache[key] = value
    }

    private func unsafe_remove(_ key: Key) {
        if let index = order.firstIndex(of: key) {
            order.remove(at: index)
            cache.removeValue(forKey: key)
        }
    }
}
