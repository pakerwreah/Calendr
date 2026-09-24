//
//  MockClipboardProvider.swift
//  Calendr
//
//  Created by Paker on 24/09/2026.
//

#if DEBUG

class MockClipboardProvider: ClipboardProviding {

    var string: String?

    func setString(_ string: String) {
        self.string = string
    }
}

#endif
