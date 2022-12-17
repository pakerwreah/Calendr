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

    private let gridView = NSGridView(numberOfColumns: 8, rows: 7)

    init(
        viewModel: CalendarViewModel,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>
    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver

        super.init(frame: .zero)

        setUpAccessibility()

        configureLayout()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.Calendar.view)
    }

    private func configureLayout() {

        gridView.wantsLayer = true
        gridView.xPlacement = .fill
        gridView.yPlacement = .fill
        gridView.rowSpacing = 0
        gridView.columnSpacing = 0

        addSubview(gridView)

        gridView.edges(to: self)
    }

    private func setUpBindings() {

        viewModel.cellSize
            .bind { [gridView] cellSize in
                for row in 0..<gridView.numberOfRows {
                    gridView.row(at: row).height = cellSize
                    /// skip week number column, because it has dynamic width
                    for col in 1..<gridView.numberOfColumns {
                        gridView.column(at: col).width = cellSize
                    }
                }
            }
            .disposed(by: disposeBag)

        viewModel.weekNumbers
            .observe(on: MainScheduler.instance)
            .map(\.isNil)
            .bind(to: gridView.column(at: 0).rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.weekNumbersWidth
            .observe(on: MainScheduler.instance)
            .map { CGFloat($0) }
            .bind(to: gridView.column(at: 0).rx.width)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.weekNumbersWidth,
            viewModel.weekDays,
            viewModel.cellSize
        )
        .map { offset, weekDays, cellSize -> [CALayer] in

            let weekends = weekDays
                .enumerated()
                .filter(\.element.isHighlighted)
                .map(\.offset)

            return IndexSet(weekends).rangeView.map { range in
                let layer = CALayer()
                layer.frame = CGRect(
                    x: offset + CGFloat(range.startIndex) * cellSize,
                    y: 0,
                    width: CGFloat(range.count) * cellSize,
                    height: 6 * cellSize
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
            let cellView = WeekDayCellView(
                weekDay: viewModel.weekDays.map(\.[i].title),
                scaling: viewModel.calendarScaling
            )
            gridView.cell(atColumnIndex: 1 + i, rowIndex: 0).contentView = cellView
        }

        for i in 0..<6 {
            let cellView = WeekNumberCellView(
                weekNumber: viewModel.weekNumbers.skipNil().map(\.[i]),
                scaling: viewModel.calendarScaling
            )
            gridView.cell(atColumnIndex: 0, rowIndex: 1 + i).contentView = cellView
        }

        for day in 0..<42 {
            let cellViewModel = viewModel
                .cellViewModelsObservable
                .map(\.[day])
                .distinctUntilChanged()
                .share(replay: 1)
                .observe(on: MainScheduler.instance)

            let cellView = CalendarCellView(
                viewModel: cellViewModel,
                hoverObserver: hoverObserver,
                clickObserver: clickObserver,
                calendarScaling: viewModel.calendarScaling
            )
            gridView.cell(atColumnIndex: 1 + day % 7, rowIndex: 1 + day / 7).contentView = cellView
        }

        rx.mouseExited
            .map(nil)
            .bind(to: hoverObserver)
            .disposed(by: disposeBag)
    }

    override func updateTrackingAreas() {

        let offsetX = gridView.column(at: 0).width
        let offsetY = gridView.row(at: 0).height

        let rect = CGRect(
            x: offsetX, y: 0,
            width: gridView.bounds.width - offsetX,
            height: gridView.bounds.height - offsetY
        )

        if let trackingArea = gridView.trackingAreas.first {
            guard trackingArea.rect != rect else { return }
            gridView.removeTrackingArea(trackingArea)
        }

        gridView.addTrackingRect(rect, owner: self, userData: nil, assumeInside: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

private enum Constants {

    static let cornerRadius: CGFloat = 5
    static let weekendBackgroundColor = NSColor.gray.cgColor.copy(alpha: 0.2)
}
