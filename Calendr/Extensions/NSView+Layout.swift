//
//  NSView+Layout.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa

protocol LayoutItem {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
}

extension NSView: LayoutItem { }
extension NSLayoutGuide: LayoutItem { }

extension NSView {

    typealias LayoutConstraints = (
        top: NSLayoutConstraint,
        trailing: NSLayoutConstraint,
        bottom: NSLayoutConstraint,
        leading: NSLayoutConstraint
    )

    typealias SizeLayoutConstraints = (
        width: NSLayoutConstraint,
        height: NSLayoutConstraint
    )

    typealias CenterLayoutConstraints = (
        horizontal: NSLayoutConstraint,
        vertical: NSLayoutConstraint
    )

    @discardableResult
    func forAutoLayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }

    @discardableResult
    func leading(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> NSLayoutConstraint {

        forAutoLayout()
            .leadingAnchor
            .constraint(equalTo: anchor, constant: constant)
            .activate()
    }

    @discardableResult
    func trailing(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0) -> NSLayoutConstraint {

        forAutoLayout()
            .trailingAnchor
            .constraint(equalTo: anchor, constant: -constant)
            .activate()
    }

    @discardableResult
    func top(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> NSLayoutConstraint {

        forAutoLayout()
            .topAnchor
            .constraint(equalTo: anchor, constant: constant)
            .activate()
    }

    @discardableResult
    func bottom(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0) -> NSLayoutConstraint {

        forAutoLayout()
            .bottomAnchor
            .constraint(equalTo: anchor, constant: -constant)
            .activate()
    }

    @discardableResult
    func leading(equalTo view: LayoutItem, constant: CGFloat = 0) -> NSLayoutConstraint {

        leading(equalTo: view.leadingAnchor, constant: constant)
    }

    @discardableResult
    func trailing(equalTo view: LayoutItem, constant: CGFloat = 0) -> NSLayoutConstraint {

        trailing(equalTo: view.trailingAnchor, constant: constant)
    }

    @discardableResult
    func top(equalTo view: LayoutItem, constant: CGFloat = 0) -> NSLayoutConstraint {

        top(equalTo: view.topAnchor, constant: constant)
    }

    @discardableResult
    func bottom(equalTo view: LayoutItem, constant: CGFloat = 0) -> NSLayoutConstraint {

        bottom(equalTo: view.bottomAnchor, constant: constant)
    }

    @discardableResult
    func edges(to view: LayoutItem, constant: CGFloat = 0) -> LayoutConstraints {
        (
            top(equalTo: view, constant: constant),
            trailing(equalTo: view, constant: constant),
            bottom(equalTo: view, constant: constant),
            leading(equalTo: view, constant: constant)
        )
    }

    @discardableResult
    func center(in view: LayoutItem, orientation: NSLayoutConstraint.Orientation, constant: CGFloat = 0) -> NSLayoutConstraint {

        forAutoLayout()

        return (
            orientation == .horizontal
                ? centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: constant)
                : centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: constant)
        )
        .activate()
    }

    @discardableResult
    func center(in view: LayoutItem, constant: CGPoint = .zero) -> CenterLayoutConstraints {
        (
            center(in: view, orientation: .horizontal, constant: constant.x),
            center(in: view, orientation: .vertical, constant: constant.y)
        )
    }

    @discardableResult
    func width(equalTo view: LayoutItem, constant: CGFloat = 0) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(equalTo: view.widthAnchor, constant: constant)
            .activate()
    }

    @discardableResult
    func width(equalTo constant: CGFloat) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(equalToConstant: constant)
            .activate()
    }

    @discardableResult
    func height(equalTo view: LayoutItem, constant: CGFloat = 0) -> NSLayoutConstraint {

        forAutoLayout()
            .heightAnchor
            .constraint(equalTo: view.heightAnchor, constant: constant)
            .activate()
    }

    @discardableResult
    func height(equalTo constant: CGFloat) -> NSLayoutConstraint {
        forAutoLayout()
            .heightAnchor
            .constraint(equalToConstant: constant)
            .activate()
    }

    @discardableResult
    func size(equalTo view: LayoutItem, constant: CGFloat = 0) -> SizeLayoutConstraints {
        (
            width(equalTo: view, constant: constant),
            height(equalTo: view, constant: constant)
        )
    }

    @discardableResult
    func size(equalTo size: CGSize) -> SizeLayoutConstraints {
        (
            width(equalTo: size.width),
            height(equalTo: size.height)
        )
    }

    @discardableResult
    func size(equalTo constant: CGFloat) -> SizeLayoutConstraints {

        size(equalTo: CGSize(width: constant, height: constant))
    }
}

// MARK: - View helpers

extension NSView {

    func with(width: CGFloat = 0) -> NSView {
        self.width(equalTo: width)
        return self
    }

    func with(height: CGFloat = 0) -> NSView {
        self.height(equalTo: height)
        return self
    }

    func with(size: CGSize) -> NSView {
        self.size(equalTo: size)
        return self
    }

    func with(size: CGFloat) -> NSView {
        self.size(equalTo: size)
        return self
    }
}

extension NSLayoutConstraint {

    @discardableResult
    func activate() -> Self {
        isActive = true
        return self
    }
}
