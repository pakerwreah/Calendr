//
//  Label.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import Cocoa
import RxSwift

enum Scaling {
    static let observable = UserDefaults.standard.rx.observe(\.textScaling).share(replay: 1)

    static var current: Double {
        var value: Double = 1
        observable.bind { value = $0 }.dispose()
        return value
    }
}

class Label: NSTextField {

    var forceVibrancy: Bool?

    override var allowsVibrancy: Bool {
        forceVibrancy ?? super.allowsVibrancy
    }

    var isEmpty: Bool {
        stringValue.isEmpty && attributedStringValue.length == 0
    }

    private var baseFont = BehaviorSubject<NSFont>(value: .systemFont(ofSize: NSFont.systemFontSize))

    override var font: NSFont? {
        get { super.font }
        set {
            guard let newValue else { return }
            baseFont.onNext(newValue)
        }
    }

    private let disposeBag = DisposeBag()

    convenience init() {
        self.init(text: "")
    }

    convenience init(text: String = "", font: NSFont? = nil, color: NSColor? = nil, align: NSTextAlignment = .left) {
        self.init(labelWithString: text)
        self.font = font
        self.textColor = color
        self.alignment = align
        setUpLayout()
        setUpBindings()
    }

    convenience init(text: NSAttributedString) {
        self.init(labelWithAttributedString: text)
        setUpLayout()
        setUpBindings()
    }

    private func setUpLayout() {
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    }

    private func setUpBindings() {

        Observable
            .combineLatest(baseFont, Scaling.observable)
            .map { font, scaling in
                font.withSize(font.pointSize * scaling)
            }
            .observe(on: MainScheduler.instance)
            .bind {
                super.font = $0
            }
            .disposed(by: disposeBag)
    }
}
