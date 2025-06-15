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
    func run(_ source: String) async throws
}

class AppleScriptRunner: ScriptRunner {

    func run(_ source: String) async throws {
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw ScriptError.source
        }
        guard script.compileAndReturnError(&errorInfo) else {
            throw ScriptError.compile(error: errorInfo?[NSAppleScript.errorMessage] as? String)
        }
        if script.executeAndReturnError(&errorInfo).description.isEmpty {
            throw ScriptError.execute(error: errorInfo?[NSAppleScript.errorMessage] as? String)
        }
    }
}
