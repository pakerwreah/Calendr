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
    private let settings: SettingsViewModel
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>

    private let gridView = NSGridView(numberOfColumns: 8, rows: 7)

    init(
        viewModel: CalendarViewModel,
        settings: SettingsViewModel,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>
    ) {

        self.viewModel = viewModel
        self.settings = settings
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

        let weekNumbersWidth = settings.showWeekNumbers.map { $0 ? Constants.cellSize : 0 }

        weekNumbersWidth
            .observe(on: MainScheduler.instance)
            .bind(to: gridView.column(at: 0).rx.width)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            weekNumbersWidth, viewModel.weekDays
        )
        .map { offset, weekDays -> [CALayer] in

            let weekends = weekDays
                .enumerated()
                .filter(\.element.isWeekend)
                .map(\.offset)

            return IndexSet(weekends).rangeView.map { range in
                let layer = CALayer()
                layer.frame = CGRect(
                    x: offset + CGFloat(range.startIndex) * Constants.cellSize,
                    y: 0,
                    width: CGFloat(range.count) * Constants.cellSize,
                    height: 6 * Constants.cellSize
                )
                layer.backgroundColor = Constants.weekendBackgroundColor
                layer.cornerRadius = Constants.cornerRadius
                return layer
            }
        }
        .scan(([], [])) { ($0.1, $1) }
        .observe(on: MainScheduler.instance)
        .bind { [gridView] oldLayers, newLayers in
            oldLayers.forEach { $0.removeFromSuperlayer() }
            newLayers.forEach(gridView.layer!.addSublayer)
        }
        .disposed(by: disposeBag)

        for i in 0..<7 {
            let cellView = WeekDayCellView(viewModel: viewModel.weekDays.map(\.[i].title))
            gridView.cell(atColumnIndex: 1 + i, rowIndex: 0).contentView = cellView
        }

        for i in 0..<6 {
            let cellView = WeekNumberCellView(viewModel: viewModel.weekNumbers.map(\.[i]))
            gridView.cell(atColumnIndex: 0, rowIndex: 1 + i).contentView = cellView
        }

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
            gridView.cell(atColumnIndex: 1 + day % 7, rowIndex: 1 + day / 7).contentView = cellView
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
