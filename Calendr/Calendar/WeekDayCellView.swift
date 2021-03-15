//
//  WeekDayCellView.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa
import RxSwift

class WeekDayCellView: NSView {

    private let disposeBag = DisposeBag()

    private let label = Label()

    init(viewModel: Observable<String>) {

        super.init(frame: .zero)

        configureLayout()

        viewModel
            .observe(on: MainScheduler.instance)
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(label)

        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.font = .boldSystemFont(ofSize: 11)
        label.size(equalTo: CGSize(width: 24, height: 13))
        label.center(in: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
