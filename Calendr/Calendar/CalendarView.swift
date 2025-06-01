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
    private var gridDisposeBag = DisposeBag()

    private let viewModel: CalendarViewModel
    private let hoverObserver: AnyObserver<Date?>
    private let clickObserver: AnyObserver<Date>
    private let doubleClickObserver: AnyObserver<Date>

    private var gridView: NSGridView?

    init(
        viewModel: CalendarViewModel,
        hoverObserver: AnyObserver<Date?>,
        clickObserver: AnyObserver<Date>,
        doubleClickObserver: AnyObserver<Date>
    ) {

        self.viewModel = viewModel
        self.hoverObserver = hoverObserver
        self.clickObserver = clickObserver
        self.doubleClickObserver = doubleClickObserver

        super.init(frame: .zero)

        setUpAccessibility()

        viewModel.weekCount.bind { [weak self] weekCount in
            guard let self else { return }

            gridDisposeBag = DisposeBag()

            configureLayout(weekCount)
            setUpBindings(weekCount)
        }
        .disposed(by: disposeBag)
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.Calendar.view)
    }

    private func configureLayout(_ weekCount: Int) {

        gridView?.removeFromSuperview()
        gridView = NSGridView(numberOfColumns: 8, rows: weekCount + 1)

        guard let gridView else { return }

        gridView.wantsLayer = true
        gridView.xPlacement = .fill
        gridView.yPlacement = .fill
        gridView.rowSpacing = 0
        gridView.columnSpacing = 0

        addSubview(gridView)

        gridView.edges(equalTo: self)
    }

    private func setUpBindings(_ weekCount: Int) {

        guard let gridView else { return }

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
            .disposed(by: gridDisposeBag)

        viewModel.weekNumbers
            .observe(on: MainScheduler.instance)
            .map(\.isNil)
            .bind(to: gridView.column(at: 0).rx.isHidden)
            .disposed(by: gridDisposeBag)

        viewModel.weekNumbersWidth
            .observe(on: MainScheduler.instance)
            .map { CGFloat($0) }
            .bind(to: gridView.column(at: 0).rx.width)
            .disposed(by: gridDisposeBag)

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
                    height: CGFloat(weekCount) * cellSize
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
        .disposed(by: gridDisposeBag)

        let combinedScaling = Observable
            .combineLatest(viewModel.calendarScaling, viewModel.calendarTextScaling)
            .map(*)
            .share(replay: 1)

        for i in 0..<7 {
            let cellView = WeekDayCellView(
                weekDay: viewModel.weekDays.map(\.[i].title),
                scaling: combinedScaling
            )
            gridView.cell(atColumnIndex: 1 + i, rowIndex: 0).contentView = cellView
        }

        for i in 0..<weekCount {
            let weekNumber = viewModel
                .weekNumbers
                .skipNil()
                .compactMap(\.[safe: i])

            let cellView = WeekNumberCellView(
                weekNumber: weekNumber,
                scaling: combinedScaling
            )
            gridView.cell(atColumnIndex: 0, rowIndex: 1 + i).contentView = cellView
        }

        for day in 0..<weekCount * 7 {
            let cellViewModel = viewModel
                .cellViewModelsObservable
                .compactMap(\.[safe: day])
                .distinctUntilChanged()
                .share(replay: 1)
                .observe(on: MainScheduler.instance)

            let cellView = CalendarCellView(
                viewModel: cellViewModel,
                hoverObserver: hoverObserver,
                clickObserver: clickObserver,
                doubleClickObserver: doubleClickObserver,
                calendarScaling: viewModel.calendarScaling,
                calendarTextScaling: viewModel.calendarTextScaling
            )
            gridView.cell(atColumnIndex: 1 + day % 7, rowIndex: 1 + day / 7).contentView = cellView
        }

        rx.mouseExited
            .map(nil)
            .bind(to: hoverObserver)
            .disposed(by: gridDisposeBag)
    }

    override func updateTrackingAreas() {

        guard let gridView else { return }

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
