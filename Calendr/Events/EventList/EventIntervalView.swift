//
//  EventIntervalView.swift
//  Calendr
//
//  Created by Paker on 01/03/2021.
//

import Cocoa
import RxSwift

class EventIntervalView: NSView {

    private let disposeBag = DisposeBag()

    init(viewModel: EventIntervalViewModel) {

        super.init(frame: .zero)

        let vdash = Label(text: "⋮", font: .systemFont(ofSize: 10), color: .labelColor)
        vdash.setContentHuggingPriority(.required, for: .horizontal)

        let label = Label(font: .systemFont(ofSize: 10), color: .labelColor, align: .right)

        viewModel.text.bind(to: label.rx.text).disposed(by: disposeBag)

        let stack = NSStackView(views: [vdash, label, .dummy]).with(spacing: 4)

        viewModel.fade.map { $0 ? 0.5 : 1 }
            .bind(to: stack.rx.alphaValue)
            .disposed(by: disposeBag)

        addSubview(stack)

        stack.edges(equalTo: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
