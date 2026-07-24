//
//  Inspect.swift
//  Calendr
//
//  Created by Paker on 24/07/2026.
//

#if DEBUG

import ObjectiveC

func inspect(_ obj: AnyObject) {
    inspect(obj.classForCoder)
}

func inspect(_ cls: AnyClass, includeMethods: Bool = false) {
    var currentClass: AnyClass? = cls

    while let current = currentClass, current != NSObject.self {
        print("=== \(String(cString: class_getName(current))) ===")
        var count: UInt32 = 0

        // 1. Properties
        if let properties = class_copyPropertyList(current, &count) {
            for i in 0..<Int(count) {
                let name = String(cString: property_getName(properties[i]))
                let type = getType(property: properties[i])
                print("Property: \(name) - \(type)")
            }
            free(properties)
        }

        // 2. Ivars
        if let ivars = class_copyIvarList(current, &count) {
            for i in 0..<Int(count) {
                if let cName = ivar_getName(ivars[i]) {
                    let type = getType(ivar: ivars[i])
                    print("Ivar: \(String(cString: cName)) - \(type)")
                }
            }
            free(ivars)
        }

        // 3. Methods
        if includeMethods, let methods = class_copyMethodList(current, &count) {
            for i in 0..<Int(count) {
                let name = NSStringFromSelector(method_getName(methods[i]))
                print("Method: \(name)")
            }
            free(methods)
        }

        print("\n")
        currentClass = class_getSuperclass(current)
    }
}

private func getType(property: objc_property_t) -> String {
    guard let attributes = property_getAttributes(property) else { return "unknown" }
    let attrString = String(cString: attributes)
    return parseType(attrString)
}

private func getType(ivar: Ivar) -> String {
    guard let attributes = ivar_getTypeEncoding(ivar) else { return "unknown" }
    let attrString = String(cString: attributes)
    return parseType(attrString)
}

private func parseType(_ attrString: String) -> String {

    // Split the comma-separated attributes (the type is always the first element)
    guard let typeAttribute = attrString.split(separator: ",").first else { return "unknown" }

    // Handle Object Types: T@"NSString" -> NSString
    if typeAttribute.hasPrefix("T@\"") && typeAttribute.hasSuffix("\"") {
        let start = typeAttribute.index(typeAttribute.startIndex, offsetBy: 3)
        let end = typeAttribute.index(typeAttribute.endIndex, offsetBy: -1)
        return String(typeAttribute[start..<end])
    }

    // Handle Primitive Types
    let typeCode = String(typeAttribute.dropFirst())
    let primitiveMap: [String: String] = [
        "c": "Int8",
        "C": "UInt8",
        "s": "Int16",
        "S": "UInt16",
        "i": "Int32",
        "I": "UInt32",
        "q": "Int",
        "Q": "UInt",
        "f": "Float",
        "d": "Double",
        "B": "Bool"
    ]

    return primitiveMap[typeCode] ?? typeCode
}

#endif
