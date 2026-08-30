//
//  TitleButton.swift
//  Calendr
//
//  Created by Paker on 30/08/2026.
//

import AppKit
import RxSwift

class TitleButton: NSButton {

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
        self.init(scaling: Scaling.observable)
    }

    convenience init(
        scaling: Observable<Double> = Scaling.observable
    ) {
        self.init(frame: .zero)

        setUpLayout()
        setUpBindings(scaling)
    }

    private func setUpLayout() {
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        refusesFirstResponder = true
    }

    private func setFont(_ font: NSFont) {
        super.font = font
    }

    private func setUpBindings(_ scaling: Observable<Double>) {

        Observable
            .combineLatest(baseFont, scaling)
            .map { font, scaling in
                font.withSize(font.pointSize * scaling)
            }
            .bind { [weak self] in
                self?.setFont($0)
            }
            .disposed(by: disposeBag)
    }
}
