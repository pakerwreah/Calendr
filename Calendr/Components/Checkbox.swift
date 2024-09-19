//
//  Checkbox.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa
import RxSwift

class Checkbox: CursorButton {

    private var baseFont = BehaviorSubject<NSFont?>(value: .systemFont(ofSize: NSFont.systemFontSize))

    override var font: NSFont? {
        get { super.font }
        set { baseFont.onNext(newValue) }
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

    private func setUpBindings() {

        Observable
            .combineLatest(baseFont, Scaling.observable)
            .compactMap { font, scaling in
                guard let font else { return nil }
                return font.withSize(font.pointSize * scaling)
            }
            .observe(on: MainScheduler.instance)
            .bind {
                super.font = $0
            }
            .disposed(by: disposeBag)
    }
}
