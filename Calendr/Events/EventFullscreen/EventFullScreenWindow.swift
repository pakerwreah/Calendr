//
//  EventFullScreenWindow.swift
//  Calendr
//
//  Created by Paker on 30/05/2026.
//

import AppKit

class EventFullScreenWindow: NSWindow {

    init(viewController: EventFullScreenViewController) {
        super.init(
            contentRect: .zero,
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level = .modalPanel
        isMovable = false
        isReleasedWhenClosed = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        contentViewController = viewController
    }

    convenience init(viewModel: EventFullScreenViewModel) {
        self.init(
            viewController: EventFullScreenViewController(
                viewModel: viewModel
            )
        )
    }

    func present(on screen: NSScreen) {
        NSApp.windows.filter(\.isModalPanel).forEach { $0.close() }
        var frame = screen.visibleFrame
        frame.size.width = screen.frame.width
        setFrame(frame, display: true, animate: false)
        makeKeyAndOrderFront(nil)
    }
}
