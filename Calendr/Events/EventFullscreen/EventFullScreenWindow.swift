//
//  EventFullScreenWindow.swift
//  Calendr
//
//  Created by Paker on 30/05/2026.
//

import AppKit

class EventFullScreenWindow: NSWindow {

    override var canBecomeKey: Bool { true }

    init(viewController: EventFullScreenViewController) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        level = .modalPanel
        isMovable = false
        isReleasedWhenClosed = false
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
        setFrame(screen.visibleFrame, display: true, animate: false)
        makeKeyAndOrderFront(nil)
    }
}
