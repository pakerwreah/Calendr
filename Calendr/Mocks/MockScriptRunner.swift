//
//  MockScriptRunner.swift
//  Calendr
//
//  Created by Paker on 15/06/2025.
//

#if DEBUG

class MockScriptRunner: ScriptRunner {

    var didRunScript: ((_ source: String) throws -> Void)?

    func run(_ source: String) async throws {
        try didRunScript?(source)
    }
}

#endif
