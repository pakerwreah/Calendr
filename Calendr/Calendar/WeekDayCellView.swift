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

    private let label = CalendarLabel()

    init(weekDay: Observable<String>, scaling: Observable<Double>) {

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        weekDay
            .observe(on: MainScheduler.instance)
            .bind(to: label.rx.text)
            .disposed(by: disposeBag)

        scaling
            .map { .boldSystemFont(ofSize: Constants.fontSize * $0) }
            .bind(to: label.rx.font)
            .disposed(by: disposeBag)
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.Calendar.weekDay)
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(label)

        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.center(in: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum Constants {

    static let fontSize: CGFloat = 11
}
