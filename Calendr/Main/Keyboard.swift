//
//  Keyboard.swift
//  Calendr
//
//  Created by Paker on 05/12/2022.
//

import AppKit

class Keyboard {

    indirect enum Key: Equatable {

        enum Arrow {
            case left
            case right
            case down
            case up
        }
        case enter
        case escape
        case backspace
        case arrow(Arrow)
        case char(Character)
        case command(Key)
        case option(Key)
    }

    private var eventMonitor: Any?

    private func removeMonitor() {
        guard let eventMonitor else { return }
        NSEvent.removeMonitor(eventMonitor)
    }

    deinit { removeMonitor() }

    func listen(in vc: NSViewController, handler: @escaping (NSEvent, Key) -> NSEvent?) {
        removeMonitor()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak vc] event in
            if vc?.view.window == event.window, let key = Key.from(event) {
                return handler(event, key)
            }
            return event
        }
    }
}

private extension Keyboard.Key {

    static func from(_ event: NSEvent) -> Self? {

        var key: Self?

        switch event.keyCode {
        case 36: key = .enter
        case 51: key = .backspace
        case 53: key = .escape
        case 123: key = .arrow(.left)
        case 124: key = .arrow(.right)
        case 125: key = .arrow(.down)
        case 126: key = .arrow(.up)
        default:
            if let char = event.charactersIgnoringModifiers?.lowercased().first {
                key = .char(char)
            }
        }

        guard var key else {
            return nil
        }

        let mods = event.modifierFlags

        if mods.contains(.option) {
            key = .option(key)
        }

        if mods.contains(.command) {
            key = .command(key)
        }

        return key
    }
}
