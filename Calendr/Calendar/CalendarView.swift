//
//  CalendarView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class CalendarView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: CalendarViewModel
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>

    private let gridView = NSGridView(numberOfColumns: 7, rows: 7)

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

    private func setUpBindings() {

        gridView.wantsLayer = true

        viewModel.weekDays.map { weekDays in

            let weekends = weekDays
                .enumerated()
                .filter(\.element.isWeekend)
                .map(\.offset)

            return IndexSet(weekends).rangeView.map { range in
                let layer = CALayer()
                layer.frame = CGRect(
                    x: CGFloat(range.startIndex) * Constants.cellSize,
                    y: 0,
                    width: CGFloat(range.count) * Constants.cellSize,
                    height: 6 * Constants.cellSize
                )
                layer.backgroundColor = Constants.weekendBackgroundColor
                layer.cornerRadius = Constants.cornerRadius
                return layer
            }
        }
        .bind(to: gridView.layer!.rx.sublayers)
        .disposed(by: disposeBag)

        viewModel.weekDays.bind { [gridView] weekDays in

            for (i, weekDay) in weekDays.map(\.title).enumerated() {

                let cellView = WeekDayCellView(weekDay: weekDay)
                gridView.cell(atColumnIndex: i, rowIndex: 0).contentView = cellView
            }
        }
        .disposed(by: disposeBag)

        for day in 0..<42 {
            let cellViewModel = viewModel
                .asObservable()
                .map(\.[day])
                .distinctUntilChanged()
                .observe(on: MainScheduler.instance)

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
    static let cornerRadius: CGFloat = 5
    static let weekendBackgroundColor = NSColor.gray.cgColor.copy(alpha: 0.2)
}
