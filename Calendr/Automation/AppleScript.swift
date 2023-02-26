//
//  AppleScript.swift
//  Calendr
//
//  Created by Paker on 26/02/23.
//

import Foundation

enum ScriptError: Error {
    case source
    case compile
    case execute
}

func runScript(_ source: String) async throws {
    guard let script = NSAppleScript(source: source) else {
        throw ScriptError.source
    }
    guard script.compileAndReturnError(nil) else {
        throw ScriptError.compile
    }
    if script.executeAndReturnError(nil).description.isEmpty {
        throw ScriptError.execute
    }
}
