//
//  YouTubeThumbnailProviderTests.swift
//  CalendrTests
//
//  Created by Paker on 09/09/2026.
//

import AppKit
import Testing
@testable import Calendr

struct YouTubeThumbnailProviderTests {

    @Test(arguments: [
        "https://youtu.be/video-id",
        "https://youtube.com/watch?v=video-id",
        "https://www.youtube.com/watch?v=video-id",
    ])
    func testSupportsYouTubeURLs(url: String) {
        #expect(YouTubeThumbnailProvider(networkProvider: MockNetworkServiceProvider()).supports(url: URL(string: url)!))
    }

    @Test(arguments: [
        "https://youtube.com/watch",
        "https://youtube.com/embed/video-id",
        "https://example.com/watch?v=video-id",
    ])
    func testDoesNotSupportOtherURLs(url: String) {
        #expect(YouTubeThumbnailProvider(networkProvider: MockNetworkServiceProvider()).supports(url: URL(string: url)!) == false)
    }

    @Test func testFetchThumbnail_fallsBackToDefaultResolution() async {

        let requestedURLs = URLRecorder()
        let networkProvider = MockNetworkServiceProvider()
        networkProvider.m_dataHandler = { url in
            requestedURLs.urls.append(url)

            return url.lastPathComponent == "hq720.jpg" ? Data() : thumbnailImageData()
        }
        let provider = YouTubeThumbnailProvider(networkProvider: networkProvider)

        let thumbnail = await provider.fetchThumbnail(
            for: URL(string: "https://youtu.be/video-id")!
        )

        #expect(thumbnail != nil)
        #expect(requestedURLs.urls.map(\.absoluteString) == [
            "https://img.youtube.com/vi/video-id/hq720.jpg",
            "https://img.youtube.com/vi/video-id/hqdefault.jpg",
        ])
    }

    @Test func testFetchThumbnail_withNetworkError_fallsBackToDefaultResolution() async {

        let requestedURLs = URLRecorder()
        let networkProvider = MockNetworkServiceProvider()
        networkProvider.m_dataHandler = { url in
            requestedURLs.urls.append(url)
            if url.lastPathComponent == "hq720.jpg" {
                throw .unexpected("error")
            }
            return thumbnailImageData()
        }
        let provider = YouTubeThumbnailProvider(networkProvider: networkProvider)

        let thumbnail = await provider.fetchThumbnail(
            for: URL(string: "https://youtu.be/video-id")!
        )

        #expect(thumbnail != nil)
        #expect(requestedURLs.urls.map(\.absoluteString) == [
            "https://img.youtube.com/vi/video-id/hq720.jpg",
            "https://img.youtube.com/vi/video-id/hqdefault.jpg",
        ])
    }
}

private final class URLRecorder {
    var urls: [URL] = []
}

private func thumbnailImageData() -> Data {
    let image = NSImage(size: .init(width: 1, height: 1))
    image.lockFocus()
    NSColor.red.setFill()
    NSBezierPath(rect: .init(x: 0, y: 0, width: 1, height: 1)).fill()
    image.unlockFocus()
    return image.tiffRepresentation!
}
