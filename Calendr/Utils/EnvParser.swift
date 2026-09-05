//
//  EnvParser.swift
//  Calendr
//
//  Created by Paker on 05/09/2026.
//

import Foundation

enum EnvParser {

    static func parse<Key: RawRepresentable<String>>(text: String) -> [Key: String] {
        var environment: [Key: String] = [:]

        let lines = text.components(separatedBy: .newlines)

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }

            guard let firstEqualsIndex = trimmedLine.firstIndex(of: "=") else {
                continue
            }

            let key = trimmedLine[..<firstEqualsIndex].trimmingCharacters(in: .whitespaces)
            var value = trimmedLine[trimmedLine.index(after: firstEqualsIndex)...].trimmingCharacters(in: .whitespaces)

            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                value = String(value.dropFirst().dropLast())
            }

            if !key.isEmpty, let key = Key(rawValue: key) {
                environment[key] = value
            }
        }

        return environment
    }
}
