//
//  TrackingView.swift
//  Calendr
//
//  Created by Paker on 14/06/2025.
//

import AppKit
import RxSwift

class TrackingView: NSView {
    let mouseEntered = PublishSubject<Void>()
    let mouseExited = PublishSubject<Void>()

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        let ta = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .inVisibleRect, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(ta)
    }

    override func mouseEntered(with event: NSEvent) { mouseEntered.onNext(()) }
    override func mouseExited(with event: NSEvent) { mouseExited.onNext(()) }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func add(to view: NSView) {
        view.addSubview(self)
        edges(equalTo: view)
    }
}
