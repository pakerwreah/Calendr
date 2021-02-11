//
//  WeekNumberCellView.swift
//  Calendr
//
//  Created by Paker on 11/02/2021.
//

import RxCocoa
import RxSwift

class WeekNumberCellView: NSView {

    private let disposeBag = DisposeBag()

    private let label = Label()

    init(viewModel: Observable<Int>) {
        
        super.init(frame: .zero)

        configureLayout()

        viewModel
            .map(String.init)
            .observe(on: MainScheduler.instance)
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(label)

        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.size(equalTo: CGSize(width: 24, height: 13))
        label.center(in: self, constant: CGPoint(x: 0, y: -3))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

