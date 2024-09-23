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

    @discardableResult
    func forAutoLayout() -> Self
}

extension NSView: LayoutItem {

    @discardableResult
    func forAutoLayout() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
}

extension NSLayoutGuide: LayoutItem {

    @discardableResult
    func forAutoLayout() -> Self {
        return self
    }
}


extension LayoutItem {

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
    func leading(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .leadingAnchor
            .constraint(equalTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func leading(lessThanOrEqualTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .leadingAnchor
            .constraint(lessThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func leading(greaterThanOrEqualTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .leadingAnchor
            .constraint(greaterThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func trailing(equalTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .trailingAnchor
            .constraint(equalTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func trailing(lessThanOrEqualTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .trailingAnchor
            .constraint(lessThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func trailing(greaterThanOrEqualTo anchor: NSLayoutXAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .trailingAnchor
            .constraint(greaterThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func top(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .topAnchor
            .constraint(equalTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func top(lessThanOrEqualTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .topAnchor
            .constraint(lessThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func top(greaterThanOrEqualTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .topAnchor
            .constraint(greaterThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func bottom(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .bottomAnchor
            .constraint(equalTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func bottom(lessThanOrEqualTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .bottomAnchor
            .constraint(lessThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func bottom(greaterThanOrEqualTo anchor: NSLayoutYAxisAnchor, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .bottomAnchor
            .constraint(greaterThanOrEqualTo: anchor, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func width(equalTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(equalTo: anchor, multiplier: multiplier, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func width(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(lessThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func width(greaterThanOrEqualTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(greaterThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func height(equalTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .heightAnchor
            .constraint(equalTo: anchor, multiplier: multiplier, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func height(lessThanOrEqualTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .heightAnchor
            .constraint(lessThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func height(greaterThanOrEqualTo anchor: NSLayoutDimension, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .heightAnchor
            .constraint(greaterThanOrEqualTo: anchor, multiplier: multiplier, constant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func leading(equalTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        leading(equalTo: view.leadingAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func leading(lessThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        leading(lessThanOrEqualTo: view.leadingAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func leading(greaterThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        leading(greaterThanOrEqualTo: view.leadingAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func trailing(equalTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        trailing(equalTo: view.trailingAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func trailing(lessThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        trailing(lessThanOrEqualTo: view.trailingAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func trailing(greaterThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        trailing(greaterThanOrEqualTo: view.trailingAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func top(equalTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        top(equalTo: view.topAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func top(lessThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        top(lessThanOrEqualTo: view.topAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func top(greaterThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        top(greaterThanOrEqualTo: view.topAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func bottom(equalTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        bottom(equalTo: view.bottomAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func bottom(lessThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        bottom(lessThanOrEqualTo: view.bottomAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func bottom(greaterThanOrEqualTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        bottom(greaterThanOrEqualTo: view.bottomAnchor, constant: constant, priority: priority)
    }

    @discardableResult
    func edges(equalTo view: LayoutItem, margin: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> LayoutConstraints {
        edges(equalTo: view, margins: NSEdgeInsets(margin), priority: priority)
    }

    @discardableResult
    func edges(equalTo view: LayoutItem, margins: NSEdgeInsets, priority: NSLayoutConstraint.Priority = .required) -> LayoutConstraints {
        (
            top(equalTo: view, constant: margins.top, priority: priority),
            trailing(equalTo: view, constant: -margins.right, priority: priority),
            bottom(equalTo: view, constant: -margins.bottom, priority: priority),
            leading(equalTo: view, constant: margins.left, priority: priority)
        )
    }

    @discardableResult
    func center(in view: LayoutItem, orientation: NSLayoutConstraint.Orientation, offset: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()

        return (
            orientation == .horizontal
                ? centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
                : centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset)
        )
        .with(priority: priority)
        .activate()
    }

    @discardableResult
    func center(in view: LayoutItem, offset: CGPoint = .zero, priority: NSLayoutConstraint.Priority = .required) -> CenterLayoutConstraints {
        (
            center(in: view, orientation: .horizontal, offset: offset.x, priority: priority),
            center(in: view, orientation: .vertical, offset: offset.y, priority: priority)
        )
    }

    @discardableResult
    func width(equalTo view: LayoutItem, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        width(equalTo: view.widthAnchor, multiplier: multiplier, constant: constant, priority: priority)
    }

    @discardableResult
    func width(equalTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(equalToConstant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func width(lessThanOrEqualTo view: LayoutItem, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        width(lessThanOrEqualTo: view.widthAnchor, multiplier: multiplier, constant: constant, priority: priority)
    }

    @discardableResult
    func width(lessThanOrEqualTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(lessThanOrEqualToConstant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func width(greaterThanOrEqualTo view: LayoutItem, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        width(greaterThanOrEqualTo: view.widthAnchor, multiplier: multiplier, constant: constant, priority: priority)
    }

    @discardableResult
    func width(greaterThanOrEqualTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .widthAnchor
            .constraint(greaterThanOrEqualToConstant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func height(equalTo view: LayoutItem, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        height(equalTo: view.heightAnchor, multiplier: multiplier, constant: constant, priority: priority)
    }

    @discardableResult
    func height(equalTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .heightAnchor
            .constraint(equalToConstant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func height(lessThanOrEqualTo view: LayoutItem, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        height(lessThanOrEqualTo: view.heightAnchor, multiplier: multiplier, constant: constant, priority: priority)
    }

    @discardableResult
    func height(lessThanOrEqualTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .heightAnchor
            .constraint(lessThanOrEqualToConstant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func height(greaterThanOrEqualTo view: LayoutItem, multiplier: CGFloat = 1, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        height(greaterThanOrEqualTo: view.heightAnchor, multiplier: multiplier, constant: constant, priority: priority)
    }

    @discardableResult
    func height(greaterThanOrEqualTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> NSLayoutConstraint {

        forAutoLayout()
            .heightAnchor
            .constraint(greaterThanOrEqualToConstant: constant)
            .with(priority: priority)
            .activate()
    }

    @discardableResult
    func size(equalTo view: LayoutItem, constant: CGFloat = 0, priority: NSLayoutConstraint.Priority = .required) -> SizeLayoutConstraints {
        (
            width(equalTo: view, constant: constant, priority: priority),
            height(equalTo: view, constant: constant, priority: priority)
        )
    }

    @discardableResult
    func size(equalTo size: CGSize, priority: NSLayoutConstraint.Priority = .required) -> SizeLayoutConstraints {
        (
            width(equalTo: size.width, priority: priority),
            height(equalTo: size.height, priority: priority)
        )
    }

    @discardableResult
    func size(equalTo constant: CGFloat, priority: NSLayoutConstraint.Priority = .required) -> SizeLayoutConstraints {

        size(equalTo: CGSize(width: constant, height: constant), priority: priority)
    }
}

// MARK: - View helpers

protocol ConfigurableView { }

/// if we extend NSView directly, it loses reference to `Self` type inside closures, like `(Self) -> Void` ¯\_(ツ)_/¯
extension ConfigurableView where Self: NSView {

    func with(width: CGFloat = 0) -> Self {
        self.width(equalTo: width)
        return self
    }

    func with(height: CGFloat = 0) -> Self {
        self.height(equalTo: height)
        return self
    }

    func with(size: CGSize) -> Self {
        self.size(equalTo: size)
        return self
    }

    func with(size: CGFloat) -> Self {
        self.size(equalTo: size)
        return self
    }

    func with(config: (Self) -> Void) -> Self {
        config(self)
        return self
    }
}

extension NSView: ConfigurableView { }

extension NSLayoutConstraint {

    @discardableResult
    func activate() -> Self {
        isActive = true
        return self
    }

    func with(priority: Priority) -> Self {
        self.priority = priority
        return self
    }
}
