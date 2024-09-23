//
//  Checkbox.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa
import RxSwift

class Checkbox: CursorButton {

    private let baseFont = BehaviorSubject<NSFont>(value: .systemFont(ofSize: NSFont.systemFontSize))

    override var font: NSFont? {
        get { super.font }
        set {
            guard let newValue else { return }
            baseFont.onNext(newValue)
        }
    }

    private let disposeBag = DisposeBag()

    init(title: String = "", cursor: NSCursor? = .pointingHand) {
        super.init(cursor: cursor)

        self.title = title
        setButtonType(.switch)
        setContentHuggingPriority(.fittingSizeCompression, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)

        setUpBindings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
