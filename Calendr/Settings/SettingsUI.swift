//
//  SettingsUI.swift
//  Calendr
//
//  Created by Paker on 20/07/24.
//

import Cocoa
import RxSwift

protocol SettingsUI: NSViewController {
    typealias Constants = SettingsUIConstants
    typealias Slider = SettingsUISlider
    typealias Sections = CompositeDisposableWrapper

    func fittingSize(minWidth: CGFloat) -> NSSize
}

extension SettingsUI {

    func fittingSize(minWidth: CGFloat) -> NSSize {
        view.fittingSize
    }

    func makeDivider() -> DisposableWrapper<NSView> {

        let divider: NSView = .spacer(height: 1)
        divider.wantsLayer = true

        let disposable = divider.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.effectiveCGColor }
            .bind(to: divider.layer!.rx.backgroundColor)

        return .init(value: divider, disposable: disposable)
    }

    func makeSection(title: String, content: NSView) -> DisposableWrapper<NSView> {

        let label = Label(text: title, font: .systemFont(ofSize: 14, weight: .semibold))

        let (divider, disposable) = makeDivider().unwrap()

        let stackView = NSStackView(views: [
            label,
            divider,
            content
        ])
        .with(orientation: .vertical)
        .with(spacing: 6)
        .with(spacing: 12, after: divider)

        stackView.setHuggingPriority(.required, for: .horizontal)

        return .init(value: stackView, disposable: disposable)
    }

    func makeToolTip(_ text: String) -> DisposableWrapper<NSView> {
        let tooltipViewController = NSViewController()
        let view = NSView()
        tooltipViewController.view = view
        let label = Label(text: text)
        label.preferredMaxLayoutWidth = 190
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        view.addSubview(label)
        label.edges(equalTo: view, margin: 12)

        let button = ImageButton(image: Icons.Settings.tooltip, cursor: nil)

        let popover = NSPopover()
        popover.contentViewController = tooltipViewController
        popover.behavior = .transient
        popover.animates = false

        let disposable = button.rx.isHovered
            .bind { isHovered in
                guard isHovered else { return popover.performClose(nil) }
                popover.show(relativeTo: .zero, of: button, preferredEdge: .maxX)
            }

        return .init(value: button, disposable: disposable)
    }

    func bind(control: NSButton, observable: Observable<Bool>, observer: AnyObserver<Bool>) -> Disposable {

        Disposables.create(
            observable
                .map { $0 ? .on : .off }
                .bind(to: control.rx.state),

            control.rx.state
                .skip(1)
                .map { $0 == .on }
                .bind(to: observer)
        )
    }

    func bind(control: NSSlider, observable: Observable<Double>, observer: AnyObserver<Double>) -> Disposable {

        Disposables.create(
            observable
                .bind(to: control.rx.value),

            control.rx.value
                .skip(1)
                .bind(to: observer)
        )
    }

    func bind(control: NSSlider, observable: Observable<Int>, observer: AnyObserver<Int>) -> Disposable {

        Disposables.create(
            observable
                .bind(to: control.rx.integerValue),

            control.rx.value
                .skip(1)
                .map(Int.init)
                .bind(to: observer)
        )
    }
}

enum SettingsUISlider {

    static func make(minValue: Double, step: Double, numberOfTickMarks: Int) -> NSSlider {
        make(
            minValue: minValue,
            maxValue: minValue + Double(numberOfTickMarks - 1) * step,
            numberOfTickMarks: numberOfTickMarks
        )
    }

    static func make(minValue: Double, maxValue: Double, numberOfTickMarks: Int) -> NSSlider {
        let slider = NSSlider(value: 0, minValue: minValue, maxValue: maxValue, target: nil, action: nil)
        slider.allowsTickMarkValuesOnly = true
        slider.numberOfTickMarks = numberOfTickMarks
        slider.controlSize = .small
        slider.refusesFirstResponder = true
        return slider
    }
}

enum SettingsUIConstants {

    static let contentSpacing: CGFloat = 24
}
