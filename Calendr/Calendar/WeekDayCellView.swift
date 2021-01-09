//
//  WeekDayCellView.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa

class WeekDayCellView: NSView {

    private static let formatter = DateFormatter()
    
    private let label = Label()

    init(weekDay: Int) {
        super.init(frame: .zero)

        forAutoLayout()

        configureLayout()

        label.stringValue = Self.formatter.veryShortWeekdaySymbols[weekDay]
    }

    private func configureLayout() {
        addSubview(label)
        label.alignment = .center
        label.textColor = .lightGray
        label.font = .boldSystemFont(ofSize: 11)
        label.center(in: self).size(equalTo: CGSize(width: 24, height: 13))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
