//
//  HostingWindowController.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import SwiftUI

protocol HostingWindowControllerDelegate: AnyObject {

    func requestWindowClose() -> Bool
}

class HostingWindowController<RootView: View>: NSHostingController<RootView>, NSWindowDelegate {

    weak var delegate: HostingWindowControllerDelegate?

    var isResizable = true

    private var isFirstLayout = true

    override init(rootView: RootView) {
        super.init(rootView: rootView)
        
        title = ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let window = view.window else {
            return assertionFailure()
        }
        window.delegate = self

        NSApp.activate(ignoringOtherApps: true)
    }

    func windowDidResize(_ notification: Notification) {
        guard isFirstLayout else {
            return
        }
        isFirstLayout = false

        guard let window = view.window else {
            return assertionFailure()
        }
        window.center()
        window.becomeKey()

        if !isResizable {
            window.styleMask.remove(.resizable)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        view.window?.performClose(sender)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        delegate?.requestWindowClose() != false
    }
}
