//
//  EventView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import RxCocoa
import RxSwift

class EventView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: EventViewModel

    private let title = Label()

    init(viewModel: EventViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        setData()

        configureLayout()

        setUpBindings()
    }

    private func setData() {

        title.stringValue = viewModel.title
    }

    private func configureLayout() {

        forAutoLayout()

        title.lineBreakMode = .byTruncatingTail

        let colorBar = NSView()
        colorBar.wantsLayer = true
        colorBar.layer?.backgroundColor = viewModel.color
        colorBar.layer?.cornerRadius = 2
        colorBar.width(equalTo: 4)

        let eventStackView = NSStackView(.vertical)
        eventStackView.addArrangedSubview(title)

        let contentStackView = NSStackView(.horizontal)
        addSubview(contentStackView)
        contentStackView.edges(to: self)
        contentStackView.addArrangedSubviews(colorBar, eventStackView)
    }

    private func setUpBindings() {
        // TODO: event in progress red line
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
