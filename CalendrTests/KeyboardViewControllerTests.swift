//
//  KeyboardViewControllerTests.swift
//  CalendrTests
//

import AppKit
import RxSwift
import Testing
@testable import Calendr

@MainActor
struct KeyboardViewControllerTests {

    @Test func shortcutControlShowsOneSectionAtATime() throws {

        let controller = KeyboardViewController(scaling: .just(1))
        _ = controller.view
        controller.view.layoutSubtreeIfNeeded()

        let control = try #require(controller.view.firstDescendant(ofType: NSSegmentedControl.self))
        let contentStackView = try #require(
            controller.view
                .firstDescendant(ofType: NSStackView.self) {
                    $0.arrangedSubviews.count == 2 && $0.arrangedSubviews.allSatisfy { $0 is NSStackView }
                }
        )

        #expect(controller.view.firstDescendant(ofType: NSScrollView.self) == nil)
        #expect(contentStackView.arrangedSubviews[0].isHidden == false)
        #expect(contentStackView.arrangedSubviews[1].isHidden == true)
        #expect(controller.view.fittingSize.height < 600)

        control.selectedSegment = 1
        _ = control.target?.perform(control.action, with: control)
        controller.view.layoutSubtreeIfNeeded()

        #expect(contentStackView.arrangedSubviews[0].isHidden == true)
        #expect(contentStackView.arrangedSubviews[1].isHidden == false)
        #expect(controller.view.fittingSize.height < 600)
    }
}

private extension NSView {

    func firstDescendant<T: NSView>(
        ofType type: T.Type,
        where predicate: @escaping (T) -> Bool = { _ in true }
    ) -> T? {

        if let match = self as? T, predicate(match) {
            return match
        }

        return subviews.lazy.compactMap { $0.firstDescendant(ofType: type, where: predicate) }.first
    }
}
