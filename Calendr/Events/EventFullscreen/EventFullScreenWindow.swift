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

        applyDesktopBlur(to: self, radius: 45)
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
        setFrame(screen.frame, display: true, animate: false)
        makeKeyAndOrderFront(nil)
    }
}

// MARK: - Hacky Window Blur

// C-Declarations to link directly into the macOS WindowServer
@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> Int32

@_silgen_name("CGSSetWindowBackgroundBlurRadius")
private func CGSSetWindowBackgroundBlurRadius(_ cid: Int32, _ wid: Int32, _ radius: Int32) -> Int32

private func applyDesktopBlur(to window: NSWindow, radius: Int) {
    let connectionID = CGSMainConnectionID()
    let windowID = Int32(window.windowNumber)

    let result = CGSSetWindowBackgroundBlurRadius(connectionID, windowID, Int32(radius))

    if result != 0 {
        print("Failed to apply window background blur. Error code: \(result)")
        window.backgroundColor = .windowBackgroundColor.withAlphaComponent(0.8)
    }
}
