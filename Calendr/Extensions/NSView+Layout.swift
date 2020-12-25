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
    func leading(equalTo view: NSView) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor)
        ])
        return self
    }

    @discardableResult
    func leading(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: anchor, constant: constant)
        ])
        return self
    }

    @discardableResult
    func trailing(equalTo view: NSView) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        return self
    }

    @discardableResult
    func trailing(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: anchor, constant: constant)
        ])
        return self
    }

    @discardableResult
    func top(equalTo view: NSView) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor)
        ])
        return self
    }

    @discardableResult
    func top(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: anchor, constant: constant)
        ])
        return self
    }

    @discardableResult
    func bottom(equalTo view: NSView) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return self
    }

    @discardableResult
    func bottom(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: anchor, constant: constant)
        ])
        return self
    }

    @discardableResult
    func edges(to view: NSView) -> Self {
        top(equalTo: view)
        bottom(equalTo: view)
        leading(equalTo: view)
        trailing(equalTo: view)
        return self
    }

    @discardableResult
    func center(in view: NSView, orientation: NSLayoutConstraint.Orientation) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            orientation == .horizontal
                ? centerXAnchor.constraint(equalTo: view.centerXAnchor)
            : centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return self
    }

    @discardableResult
    func center(in view: NSView) -> Self {
        center(in: view, orientation: .horizontal)
        center(in: view, orientation: .vertical)
        return self
    }

    @discardableResult
    func width(equalTo view: NSView) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        return self
    }

    @discardableResult
    func width(equalTo constant: CGFloat) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: constant)
        ])
        return self
    }

    @discardableResult
    func height(equalTo view: NSView) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        return self
    }

    @discardableResult
    func height(equalTo constant: CGFloat) -> Self {
        forAutoLayout()
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: constant)
        ])
        return self
    }

    @discardableResult
    func size(equalTo view: NSView) -> Self {
        width(equalTo: view)
        height(equalTo: view)
        return self
    }

    @discardableResult
    func size(equalTo size: CGSize) -> Self {
        width(equalTo: size.width)
        height(equalTo: size.height)
        return self
    }

    @discardableResult
    func size(equalTo constant: CGFloat) -> Self {
        size(equalTo: CGSize(width: constant, height: constant))
        return self
    }
}
