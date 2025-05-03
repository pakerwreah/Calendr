//
//  SettingsUI.swift
//  Calendr
//
//  Created by Paker on 20/07/24.
//

import Cocoa
import RxSwift

protocol SettingsUI {
    typealias Constants = SettingsUIConstants
    typealias Slider = SettingsUISlider
    typealias Sections = CompositeDisposableWrapper
}

extension SettingsUI {

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
