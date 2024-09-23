//
//  Radio.swift
//  Calendr
//
//  Created by Paker on 30/01/21.
//

import Cocoa
import RxSwift

class Radio: NSButton {

    private let baseFont = BehaviorSubject<NSFont>(value: .systemFont(ofSize: NSFont.systemFontSize))

    override var font: NSFont? {
        get { super.font }
        set {
            guard let newValue else { return }
            baseFont.onNext(newValue)
        }
    }

    private let disposeBag = DisposeBag()

    convenience init(title: String = "") {
        self.init(radioButtonWithTitle: title, target: nil, action: nil)
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        refusesFirstResponder = true
        setUpBindings()
    }

    private func setFont(_ font: NSFont) {
        super.font = font
    }

    private func setUpBindings() {

        Observable
            .combineLatest(baseFont, Scaling.observable)
            .map { font, scaling in
                font.withSize(font.pointSize * scaling)
            }
            .bind { [weak self] in
                self?.setFont($0)
            }
            .disposed(by: disposeBag)
    }
}
