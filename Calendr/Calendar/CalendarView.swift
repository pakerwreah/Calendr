//
//  CalendarView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class CalendarView: NSView {

    private let gridView = NSGridView(numberOfColumns: 7, rows: 7)

    private let viewModel: CalendarViewModel
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>

    init(
        viewModel: CalendarViewModel,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>
    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver

        super.init(frame: .zero)

        configureLayout()

        addWeekendLayers()

        setUpBindings()
    }

    private func configureLayout() {
        gridView.xPlacement = .fill
        gridView.yPlacement = .fill
        gridView.rowSpacing = 0
        gridView.columnSpacing = 0

        for row in 0..<gridView.numberOfRows {
            gridView.row(at: row).height = Constants.cellSize
            for col in 0..<gridView.numberOfColumns {
                gridView.column(at: col).width = Constants.cellSize
            }
        }

        addSubview(gridView)

        gridView.edges(to: self)
    }

    private func addWeekendLayers() {
        gridView.wantsLayer = true

        let cellSize = Constants.cellSize

        for col: CGFloat in [0, 6] {
            let layer = CALayer()
            layer.frame = CGRect(x: CGFloat(col) * cellSize, y: 0, width: cellSize, height: 6 * cellSize)
            layer.backgroundColor = NSColor.gray.withAlphaComponent(0.2).cgColor
            layer.cornerRadius = 5
            gridView.layer?.addSublayer(layer)
        }
    }

    private func setUpBindings() {

        for weekDay in 0..<7 {
            let cellView = WeekDayCellView(weekDay: weekDay)
            gridView.cell(atColumnIndex: weekDay, rowIndex: 0).contentView = cellView
        }

        for day in 0..<42 {
            let cellViewModel = viewModel
                .asObservable()
                .map(\.[day])
                .distinctUntilChanged()
                .observe(on: MainScheduler.asyncInstance)

            let cellView = CalendarCellView(
                viewModel: cellViewModel,
                hoverObserver: hoverObserver,
                clickObserver: clickObserver
            )
            gridView.cell(atColumnIndex: day % 7, rowIndex: 1 + day / 7).contentView = cellView
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private enum Constants {

    static let cellSize: CGFloat = 25
}
