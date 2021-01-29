//
//  WeekDayCellView.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa

class WeekDayCellView: NSView {

    private let label = Label()

    init(weekDay: String) {
        super.init(frame: .zero)

        configureLayout()

        label.stringValue = weekDay
    }

    private func configureLayout() {

        forAutoLayout()

        addSubview(label)

        label.alignment = .center
        label.textColor = .secondaryLabelColor
        label.font = .boldSystemFont(ofSize: 11)
        label.center(in: self).size(equalTo: CGSize(width: 24, height: 13))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
