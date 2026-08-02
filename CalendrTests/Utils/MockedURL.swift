//
//  MockedURL.swift
//  Calendr
//
//  Created by Paker on 02/08/2026.
//

import AppKit

class MockedURL: NSURL, @unchecked Sendable {

    var resourceValues: [URLResourceKey : Any] = [:]

    override func resourceValues(forKeys keys: [URLResourceKey]) throws -> [URLResourceKey : Any] {
        return resourceValues
    }
}

func mockAppUrl(_ name: String) -> URL {
    let path = "/path/Applications/\(name).app".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
    let url = MockedURL(string: path)!
    url.resourceValues[.nameKey] = "\(name).app"
    url.resourceValues[.effectiveIconKey] = NSImage()
    return url as URL
}
