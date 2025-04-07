//
//  KVCError.swift
//  Calendr
//
//  Created by Paker on 06/04/2025.
//

import Foundation

enum KVCError: LocalizedError {
    case unknownKey(key: String, type: String)
    case typeMismatch(key: String, source: String, target: String)

    var errorDescription: String? {
        switch self {
        case .unknownKey(let key, let type):
            return "Unknown key \"\(key)\" in \(type)"
        case .typeMismatch(let key, let source, let target):
            return "Type mismatch for key \"\(key)\": \(source) -> \(target)"
        }
    }
}

extension NSObject {

    func safeValue<T>(forKey key: String) throws -> T {
        var result: Any?
        var caughtException: NSException?

        ExceptionCatcher.try({
            result = self.value(forKey: key)
        }) { exception in
            caughtException = exception
        }

        if caughtException != nil {
            throw KVCError.unknownKey(key: key, type: "\(className)")
        }

        guard let result = result as? T else {
            throw KVCError.typeMismatch(key: key, source: "\(object_getClass(result)?.description() ?? "Unknown") ", target: "\(T.self)")
        }

        return result
    }
}
