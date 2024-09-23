//
//  Label.swift
//  Calendr
//
//  Created by Paker on 25/12/20.
//

import Cocoa
import RxSwift

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

    convenience init(
        text: String = "",
        font: NSFont? = nil,
        color: NSColor? = nil,
        align: NSTextAlignment = .left,
        scaling: Observable<Double> = Scaling.observable
    ) {
        self.init(labelWithString: text)
        self.font = font
        self.textColor = color
        self.alignment = align
        setUpLayout()
        setUpBindings(scaling)
    }

    convenience init(text: NSAttributedString) {
        self.init(labelWithAttributedString: text)
        setUpLayout()
    }

    private func setUpLayout() {
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
    }

    private func setUpBindings(_ scaling: Observable<Double>) {

        Observable
            .combineLatest(baseFont, scaling)
            .map { font, scaling in
                font.withSize(font.pointSize * scaling)
            }
            .bind {
                super.font = $0
            }
            .disposed(by: disposeBag)
    }
}
