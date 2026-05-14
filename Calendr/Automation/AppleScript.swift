//
//  AppleScript.swift
//  Calendr
//
//  Created by Paker on 26/02/23.
//

import Foundation

enum ScriptError: LocalizedError {
    case source
    case compile(error: String?)
    case execute(error: String?)

    var errorDescription: String? {
        switch self {
        case .compile(let error), .execute(let error):
            return error
        case .source:
            return "Unknown source error"
        }
    }
}

protocol ScriptRunner {
    @MainActor
    func run(_ source: String) throws
}

class AppleScriptRunner: ScriptRunner {

    func run(_ source: String) throws {
        assert(!source.contains("delay "), "Don't use 'delay', it causes memory leak.")

        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw ScriptError.source
        }
        script.compileAndReturnError(&errorInfo)
        if let errorInfo {
            throw ScriptError.compile(error: errorInfo.errorMessage)
        }
        script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw ScriptError.execute(error: errorInfo.errorMessage)
        }
    }
}

private extension NSDictionary {

    var errorMessage: String? {
        self[NSAppleScript.errorMessage] as? String
    }
}
