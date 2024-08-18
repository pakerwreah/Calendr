//
//  MockNetworkServiceProvider.swift
//  Calendr
//
//  Created by Paker on 18/08/2024.
//

#if DEBUG

import Foundation

class MockNetworkServiceProvider: NetworkServiceProviding {
    
    func data(from url: URL) async throws -> Data {
        throw UnexpectedError(message: "Not mocked")
    }
    
    func download(from url: URL) async throws -> URL {
        throw UnexpectedError(message: "Not mocked")
    }
}

#endif
