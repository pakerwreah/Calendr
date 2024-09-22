//
//  SyncLocalizations.swift
//  Calendr
//
//  Created by Paker on 22/09/2024.
//

import Foundation

struct SyncLocalizations {

    struct Error: LocalizedError {

        let message: String

        init(_ message: String) {
            self.message = message
        }

        var errorDescription: String? { message }
    }

    static func main() throws {

        guard let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] else {
            throw Error("Missing SRCROOT environment variable.")
        }
        guard let targetName = ProcessInfo.processInfo.environment["TARGET_NAME"] else {
            throw Error("Missing TARGET_NAME environment variable.")
        }
        let assetsPath = "\(srcRoot)/\(targetName)/Assets"

        // Function to get supported languages based on .lproj directories
        func getSupportedLanguages() throws -> [String] {
            let fileManager = FileManager.default
            guard let contents = try? fileManager.contentsOfDirectory(atPath: assetsPath) else {
                throw Error("Failed to read Assets directory.")
            }

            return contents.compactMap { item -> String? in
                if item.hasSuffix(".lproj"), item != "en.lproj" {
                    return String(item.dropLast(6)) // Remove ".lproj"
                }
                return nil
            }
        }

        // Function to parse a localization file into a dictionary
        func parseLocalizationFile(at path: String) throws -> (header: String, keys: [String], result: [String: String]) {
            guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
                throw Error("Failed to read file at path: \(path)")
            }

            guard contents.hasPrefix("/*") else {
                throw Error("Missing header comment in file at path: \(path)")
            }

            var header = ""
            var keys: [String] = []
            var result: [String: String] = [:]

            var error: Error?

            var parsingHeader = true

            contents.enumerateLines { rawLine, stop in
                guard !parsingHeader else {
                    header.append(rawLine + "\n")
                    parsingHeader = !rawLine.hasSuffix("*/")
                    return
                }

                let line = rawLine.trimmingCharacters(in: .whitespaces)

                guard !line.isEmpty else {
                    keys.append("")
                    return
                }

                guard !line.hasPrefix("//") else {
                    return
                }

                let components = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
                guard components.count == 2, line.hasSuffix(";") else {
                    error = Error("Corrupted localization file at path: \(path)\nLine: \(line)")
                    stop = true
                    return
                }
                let key = components[0].description.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                let value = components[1].trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
                keys.append(key)
                result[key] = value
            }

            if let error {
                throw error
            }

            return (header, keys, result)
        }

        func writeFile(content: String, to path: String) throws {
            do {
                try content.write(toFile: path, atomically: true, encoding: .utf8)
            } catch {
                throw Error("Failed to write file at path: \(path)")
            }
        }

        // Function to sync localizations
        func syncLocalizations() throws {
            let enLocalizationPath = "\(assetsPath)/en.lproj/Localizable.strings"
            let (_, lineKeys, enLocalizations) = try parseLocalizationFile(at: enLocalizationPath)
            let supportedLanguages = try getSupportedLanguages()

            print("Supported languages:", supportedLanguages)

            var missingLang: [(lang: String, path: String)] = []

            for language in supportedLanguages {
                let localizationPath = "\(assetsPath)/\(language).lproj/Localizable.strings"
                var (header, _, localizations) = try parseLocalizationFile(at: localizationPath)

                var hasMissing = false
                var missingKeys: Set<String> = []

                // Add missing keys
                for (key, value) in enLocalizations {
                    if localizations[key] == nil {
                        missingKeys.insert(key)
                        localizations[key] = value
                        hasMissing = true
                    }
                }

                // Remove non-existing keys
                for key in localizations.keys where enLocalizations[key] == nil {
                    localizations.removeValue(forKey: key)
                }

                var content = header
                for key in lineKeys {
                    guard !key.isEmpty else {
                        content.append("\n")
                        continue
                    }
                    let value = localizations[key]!
                    let comment = missingKeys.contains(key) ? "//" : ""

                    content.append("\(comment)\"\(key)\" = \"\(value)\";\n")
                }

                // Write updated localizations back to the file
                try writeFile(content: content, to: localizationPath)

                if hasMissing {
                    missingLang.append((language, "\(targetName)/Assets/\(language).lproj/Localizable.strings"))
                }
            }

            let body = missingLang.map { lang, path in

                let locale = Locale(identifier: lang)
                let enLocale = Locale(identifier: "en")
                let nativeName = locale.localizedString(forLanguageCode: lang) ?? ""
                let englishName = enLocale.localizedString(forLanguageCode: lang) ?? ""
                let languageNames = [englishName, nativeName, "(\(lang))"].joined(separator: " - ")

                return "- [\(languageNames)](\(path))"

            }.joined(separator: "\n")

            let missingTranslationsPath = "\(srcRoot)/MISSING_TRANSLATIONS.md"

            guard !body.isEmpty else {
                try FileManager.default.removeItem(atPath: missingTranslationsPath)
                return
            }

            let content = "# The following languages have missing translations\n\(body)\n\n"
            + "Feel free to open a new issue or pull request with the missing values.\n\n"
            + "All missing translations in the files start with a `//`.\n\n"
            + "<sub>This file is auto-generated and should be always up to date.</sub>\n"

            try writeFile(content: content, to: missingTranslationsPath)
        }

        try syncLocalizations()
    }
}

do {
    try SyncLocalizations.main()
} catch {
    print("error: \(error.localizedDescription)")
}
