//
//  NSView+Layout.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

extension NSView {

    @discardableResult
    func forAutoLayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }

    @discardableResult
    func leading(equalTo anchor: NSLayoutXAxisAnchor,
                 constant: CGFloat = 0,
                 priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: anchor, constant: constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func trailing(equalTo anchor: NSLayoutXAxisAnchor,
                  constant: CGFloat = 0,
                  priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: anchor, constant: -constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func top(equalTo anchor: NSLayoutYAxisAnchor,
             constant: CGFloat = 0,
             priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: anchor, constant: constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func bottom(equalTo anchor: NSLayoutYAxisAnchor,
                constant: CGFloat = 0,
                priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: anchor, constant: -constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func leading(equalTo view: NSView,
                 constant: CGFloat = 0,
                 priority: NSLayoutConstraint.Priority = .required) -> Self {
        leading(equalTo: view.leadingAnchor, constant: constant, priority: priority)
        return self
    }

    @discardableResult
    func trailing(equalTo view: NSView,
                  constant: CGFloat = 0,
                  priority: NSLayoutConstraint.Priority = .required) -> Self {
        trailing(equalTo: view.trailingAnchor, constant: constant, priority: priority)
        return self
    }

    @discardableResult
    func top(equalTo view: NSView,
             constant: CGFloat = 0,
             priority: NSLayoutConstraint.Priority = .required) -> Self {
        top(equalTo: view.topAnchor, constant: constant, priority: priority)
        return self
    }

    @discardableResult
    func bottom(equalTo view: NSView,
                constant: CGFloat = 0,
                priority: NSLayoutConstraint.Priority = .required) -> Self {
        bottom(equalTo: view.bottomAnchor, constant: constant, priority: priority)
        return self
    }

    @discardableResult
    func edges(to view: NSView,
               constant: CGFloat = 0,
               priority: NSLayoutConstraint.Priority = .required) -> Self {
        top(equalTo: view, constant: constant, priority: priority)
        bottom(equalTo: view, constant: constant, priority: priority)
        leading(equalTo: view, constant: constant, priority: priority)
        trailing(equalTo: view, constant: constant, priority: priority)
        return self
    }

    @discardableResult
    func center(in view: NSView,
                orientation: NSLayoutConstraint.Orientation,
                priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            (
                orientation == .horizontal
                    ? centerXAnchor.constraint(equalTo: view.centerXAnchor)
                    : centerYAnchor.constraint(equalTo: view.centerYAnchor)
            )
            .with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func center(in view: NSView, priority: NSLayoutConstraint.Priority = .required) -> Self {
        center(in: view, orientation: .horizontal, priority: priority)
        center(in: view, orientation: .vertical, priority: priority)
        return self
    }

    @discardableResult
    func width(equalTo view: NSView,
               constant: CGFloat = 0,
               priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: view.widthAnchor, constant: constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func width(equalTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func height(equalTo view: NSView,
                constant: CGFloat = 0,
                priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: view.heightAnchor, constant: constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func height(equalTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: constant).with(priority: priority)
        ])
        return self
    }

    @discardableResult
    func size(equalTo view: NSView,
              constant: CGFloat = 0,
              priority: NSLayoutConstraint.Priority = .required) -> Self {
        width(equalTo: view, constant: constant, priority: priority)
        height(equalTo: view, constant: constant, priority: priority)
        return self
    }

    @discardableResult
    func size(equalTo size: CGSize, priority: NSLayoutConstraint.Priority = .required) -> Self {
        width(equalTo: size.width, priority: priority)
        height(equalTo: size.height, priority: priority)
        return self
    }

    @discardableResult
    func size(equalTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> Self {
        size(equalTo: CGSize(width: constant, height: constant), priority: priority)
        return self
    }
}

extension NSLayoutConstraint {

    func with(priority: NSLayoutConstraint.Priority) -> Self {
        self.priority = priority
        return self
    }
}
