//
//  Keyboard.swift
//  Calendr
//
//  Created by Paker on 05/12/2022.
//

import AppKit

class Keyboard {

    enum Key: Equatable {

        enum Arrow {
            case left
            case right
            case down
            case up
        }
        case escape
        case arrow(Arrow)
        case command(Character)

        static func from(_ event: NSEvent) -> Self? {
            switch event.keyCode {
            case 53: return .escape
            case 123: return .arrow(.left)
            case 124: return .arrow(.right)
            case 125: return .arrow(.down)
            case 126: return .arrow(.up)
            default:
                if event.modifierFlags.contains(.command), let char = event.characters?.first {
                    return .command(char)
                }
            }
            return nil
        }
    }

    private var eventMonitor: Any?

    private func removeMonitor() {
        guard let eventMonitor else { return }
        NSEvent.removeMonitor(eventMonitor)
    }

    deinit { removeMonitor() }

    var handler: ((NSEvent) -> NSEvent?)? {
        willSet {
            removeMonitor()
        }
        didSet {
            eventMonitor = handler.flatMap { NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: $0) }
        }
    }
}
