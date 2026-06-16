//
//  MockNetworkServiceProvider.swift
//  Calendr
//
//  Created by Paker on 18/08/2024.
//

#if DEBUG

import Foundation

class MockNetworkServiceProvider: NetworkServiceProviding {

    var m_dataHandler: ((URL) async throws -> Data)?
    var m_downloadHandler: ((URL) async throws -> URL)?

    func data(from url: URL) async throws -> Data {
        guard let handler = m_dataHandler else {
            throw UnexpectedError(message: "data not mocked")
        }
        return try await handler(url)
    }

    func download(from url: URL) async throws -> URL {
        guard let handler = m_downloadHandler else {
            throw UnexpectedError(message: "download not mocked")
        }
        return try await handler(url)
    }
}

#endif
