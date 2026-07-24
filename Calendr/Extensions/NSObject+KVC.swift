//
//  NSObject+KVC.swift
//  Calendr
//
//  Created by Paker on 19/11/2025.
//

import Foundation
#if canImport(CalendrObjC)
import CalendrObjC
#endif

enum KVCError: LocalizedError {
    case unknownKey(key: String, in: String)
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

        var keyExists = ObjCBool(false)

        let result = ExceptionCatcher.safeValue(forKey: key, in: self, keyExists: &keyExists)

        guard keyExists.boolValue else {
            throw KVCError.unknownKey(key: key, in: typeName(self))
        }

        guard let result = result as? T else {
            throw KVCError.typeMismatch(key: key, source: typeName(result), target: "\(T.self)")
        }

        return result
    }
}

private func typeName(_ object: Any?) -> String {
    guard let object else { return "Unknown" }
    return String(describing: type(of: object))
}
