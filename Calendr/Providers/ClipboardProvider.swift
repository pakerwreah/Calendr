//
//  ClipboardProvider.swift
//  Calendr
//
//  Created by Paker on 24/09/2026.
//

import AppKit

protocol ClipboardProviding {
    func setString(_ string: String)
}

struct ClipboardProvider: ClipboardProviding {

    fileprivate let clipboard: NSPasteboard

    func setString(_ string: String) {
        clipboard.clearContents()
        clipboard.setString(string, forType: .string)
    }
}

private let _shared = ClipboardProvider(
    clipboard: BuildConfig.isTesting ? .withUniqueName() : .general
)

extension ClipboardProviding where Self == ClipboardProvider {

    static var shared: Self { _shared }
}
