//
//  Popover.swift
//  Calendr
//
//  Created by Paker on 14/04/24.
//

import AppKit

var popovers: [Popover] = []

@objc protocol PopoverDelegate {
    @objc optional func popoverWillShow()
    @objc optional func popoverDidShow()
    @objc optional func popoverWillClose()
    @objc optional func popoverDidClose()
}

class Popover: NSObject, PopoverWindowDelegate {

    private var window: PopoverWindow?
    private var isClosing = false

    var contentViewController: NSViewController?
    var delegate: PopoverDelegate?
    var behavior: NSPopover.Behavior = .transient

    func show(from view: NSView) {
        present(from: view, edge: .maxY, spacing: 0, single: true)
    }

    func push(from view: NSView) {
        present(from: view, edge: .minX, spacing: 8, single: false)
    }

    func present(from view: NSView, edge: NSRectEdge, spacing: CGFloat, single: Bool) {

        if let window {
            return window.move(to: view, edge: edge, spacing: spacing)
        }

        if single {
            closeAll()
        }

        guard let contentViewController else { return }

        delegate?.popoverWillShow?()

        let contentView = contentViewController.view.forAutoLayout()
        let container = NSVisualEffectView()
        container.maskImage = .mask(withCornerRadius: 12)
        container.state = .active
        container.addSubview(contentView)
        container.edges(to: contentView)

        let window = PopoverWindow()
        window.contentView = container
        window.isOpaque = false
        window.backgroundColor = .clear
        window.styleMask = .borderless
        window.level = .floating
        window.isReleasedWhenClosed = false
        window._delegate = self
        window.move(to: view, edge: edge, spacing: spacing)
        window.activate()

        delegate?.popoverDidShow?()

        self.window = window

        popovers.append(self)
    }

    private var isMouseInside: Bool {
        guard let window else { return false }
        return NSMouseInRect(NSEvent.mouseLocation, window.frame, false)
    }

    private func closeAll() {
        for popover in popovers {
            popover.window?.performClose(nil)
        }
    }

    func windowDidResignKey(_ notification: Notification) {

        guard !isClosing else {
            return
        }

        guard NSApp.isActive else {
            return closeAll()
        }

        guard !isMouseInside else {
            return
        }

        window?.performClose(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        behavior == .transient
    }

    func windowWillClose(_ notification: Notification) {
        isClosing = true
        let wasTop = popovers.last == self

        delegate?.popoverWillClose?()
        popovers.removeAll { $0 == self }
        delegate?.popoverDidClose?()

        guard wasTop, let newTop = popovers.last?.window else {
            return
        }

        newTop.activate()
    }
}

@objc protocol PopoverWindowDelegate: NSWindowDelegate {
    @objc optional func windowDidClose()
}

private class PopoverWindow: NSWindow {

    override weak var delegate: NSWindowDelegate? {
        set {
            assert(newValue == nil)
            _delegate = nil
        }
        get { _delegate }
    }

    weak var _delegate: PopoverWindowDelegate? {
        didSet {
            super.delegate = _delegate
        }
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func keyDown(with event: NSEvent) {
        if Keyboard.Key.from(event) == .escape {
            performClose(nil)
        } else {
            super.keyDown(with: event)
        }
    }

    override func performClose(_ sender: Any?) {
        guard delegate?.windowShouldClose?(self) != false else {
            return
        }
        close()
    }

    override func close() {
        super.close()
        _delegate?.windowDidClose?()
    }

    func activate() {
        makeKeyAndOrderFront(nil)
        NSRunningApplication.current.activate()
        NSApp.activate(ignoringOtherApps: true)
        makeFirstResponder(nil)
    }

    func move(to anchor: NSView, edge: NSRectEdge, spacing: CGFloat) {

        if let origin = relativePosition(to: anchor, edge: edge, spacing: spacing) {
            setFrameOrigin(origin)
        }
    }

    private func relativePosition(to view: NSView, edge: NSRectEdge, spacing: CGFloat) -> NSPoint? {
        
        guard let viewWindow = view.window, let screen = NSScreen.main else {
            return nil
        }

        struct Limits {
            let minX: CGFloat
            let maxX: CGFloat
            let minY: CGFloat
            let maxY: CGFloat
        }

        let limit = Limits(
            minX: screen.visibleFrame.minX,
            maxX: screen.visibleFrame.maxX - frame.width,
            minY: screen.visibleFrame.minY,
            maxY: screen.visibleFrame.maxY - frame.height
        )

        // screen coordinates are inverted
        let viewFrame = viewWindow.convertToScreen(view.convert(view.bounds, to: nil))

        var position: NSPoint?

        let centerX = min(limit.maxX, max(limit.minX, viewFrame.midX - frame.width / 2))
        let centerY = min(limit.maxY, max(limit.minY, viewFrame.midY - frame.height / 2))

        switch edge {
        case .minX:
            position = NSPoint(x: max(limit.minX, viewFrame.minX - frame.width - spacing), y: centerY)
        case .maxX:
            position = NSPoint(x: min(limit.maxX, viewFrame.maxX + spacing), y: centerY)
        case .minY:
            position = NSPoint(x: centerX, y: min(limit.maxY, viewFrame.maxY + spacing))
        case .maxY:
            position = NSPoint(x: centerX, y: max(limit.minY, viewFrame.minY - frame.height - spacing))
        default:
            break
        }

        return position
    }
}

private extension NSImage {

    static func mask(withCornerRadius radius: CGFloat) -> NSImage {
        
        let image = NSImage(size: NSSize(width: radius * 2, height: radius * 2), flipped: false) {
            NSBezierPath(roundedRect: $0, xRadius: radius, yRadius: radius).fill()
            NSColor.black.set()
            return true
        }

        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch

        return image
    }
}
