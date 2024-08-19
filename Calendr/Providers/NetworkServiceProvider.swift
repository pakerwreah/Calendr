//
//  NetworkServiceProvider.swift
//  Calendr
//
//  Created by Paker on 18/08/2024.
//

import Foundation

protocol NetworkServiceProviding {
    func data(from url: URL) async throws -> Data
    func download(from url: URL) async throws -> URL
}

class NetworkServiceProvider: NetworkServiceProviding {

    func data(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    func download(from url: URL) async throws -> URL {
        let (url, _) = try await URLSession.shared.download(from: url)
        return url
    }
}
