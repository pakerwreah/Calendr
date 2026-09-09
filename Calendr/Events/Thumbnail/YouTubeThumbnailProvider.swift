//
//  YouTubeThumbnailProvider.swift
//  Calendr
//
//  Created by Paker on 09/09/2026.
//

import Cocoa

final class YouTubeThumbnailProvider: ThumbnailProviding {

    private let networkProvider: NetworkServiceProviding

    init(networkProvider: NetworkServiceProviding) {
        self.networkProvider = networkProvider
    }

    func supports(url: URL) -> Bool {
        videoId(from: url) != nil
    }

    func fetchThumbnail(for url: URL) async -> NSImage? {
        guard let videoId = videoId(from: url) else { return nil }

        for resolution in ["hq720", "hqdefault"] {
            guard
                let thumbnailURL = URL(string: "https://img.youtube.com/vi/\(videoId)/\(resolution).jpg"),
                let data = try? await networkProvider.data(from: thumbnailURL),
                let image = NSImage(data: data)
            else { continue }

            return image
        }

        return nil
    }
}

private func videoId(from url: URL) -> String? {
    guard let host = url.host?.lowercased() else { return nil }

    if host == "youtu.be" {
        return url.pathComponents.dropFirst().first
    }

    guard
        ["youtube.com", "www.youtube.com", "m.youtube.com"].contains(host),
        url.path == "/watch"
    else { return nil }

    return URLComponents(
        url: url,
        resolvingAgainstBaseURL: false
    )?.queryItems?.first(where: { $0.name == "v" })?.value
}
