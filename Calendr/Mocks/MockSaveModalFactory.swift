//
//  MockSaveModalFactory.swift
//  Calendr
//
//  Created by Paker on 16/06/2026.
//

#if DEBUG

import AppKit

class MockSaveModal: SaveModal {

    var url: URL?
    private let onBegin: () async -> NSApplication.ModalResponse

    init(url: URL?, onBegin: @escaping () async -> NSApplication.ModalResponse) {
        self.url = url
        self.onBegin = onBegin
    }

    func begin() async -> NSApplication.ModalResponse {
        await onBegin()
    }
}

class MockSaveModalFactory: SaveModalFactory {

    var response: NSApplication.ModalResponse = .OK
    var url: URL?
    var hang = false

    private(set) var spyMakeCalled = false
    private(set) var spyMakeURL: URL?

    /// Holds a hanging modal so the awaiting install task can be released via `cancel()`.
    private var hangTask: Task<NSApplication.ModalResponse, Never>?

    func make(for url: URL) -> SaveModal {
        spyMakeCalled = true
        spyMakeURL = url

        let response = response
        let modalURL = self.url ?? url

        guard hang else {
            return MockSaveModal(url: modalURL) { response }
        }

        // simulate a modal that never returns until cancelled
        let task = Task<NSApplication.ModalResponse, Never> {
            do {
                try await Task.sleep(for: .seconds(3600))
                return response
            } catch {
                return .cancel
            }
        }
        hangTask = task

        return MockSaveModal(url: modalURL) { await task.value }
    }

    /// Releases a hanging modal so the install flow can unwind cleanly.
    func cancel() {
        hangTask?.cancel()
        hangTask = nil
    }
}

#endif
