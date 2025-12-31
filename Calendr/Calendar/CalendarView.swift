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

    private let outlineLayer = CAShapeLayer()

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

        setUpOutline()

        setUpBindings()

        viewModel.weekCount.bind { [weak self] weekCount in
            guard let self else { return }

            gridDisposeBag = DisposeBag()

            setUpGridLayout(weekCount)
            setUpGridBindings(weekCount)
        }
        .disposed(by: disposeBag)
    }

    override func updateLayer() {
        super.updateLayer()
        outlineLayer.strokeColor = Colors.outlineBackground
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        setAccessibilityElement(true)
        setAccessibilityIdentifier(Accessibility.Calendar.view)
    }

    private func setUpOutline() {

        outlineLayer.fillColor = nil
        outlineLayer.lineWidth = Constants.outlineWidth

        wantsLayer = true
        layer!.addSublayer(outlineLayer)
    }

    private func setUpBindings() {

        viewModel.showMonthOutline.map(!)
            .bind(to: outlineLayer.rx.isHidden)
            .disposed(by: disposeBag)

        rx.mouseExited
            .map(nil)
            .bind(to: hoverObserver)
            .disposed(by: disposeBag)
    }

    private func setUpGridLayout(_ weekCount: Int) {

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

    private func setUpGridBindings(_ weekCount: Int) {

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
        .repeat(when: rx.updateLayer)
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
                layer.backgroundColor = Colors.weekendBackground
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

        var dateViews: [NSView] = []

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

            dateViews.append(cellView)

            gridView.cell(atColumnIndex: 1 + day % 7, rowIndex: 1 + day / 7).contentView = cellView
        }

        let updateSize = rx.observe(\.frame).distinctUntilChanged(\.size).void()

        viewModel.cellViewModelsObservable
            .repeat(when: updateSize)
            .observe(on: MainScheduler.instance)
            .compactMap {
                let inset = Constants.outlineInset

                let frames = $0.enumerated().compactMap { day, vm -> NSRect? in
                    guard vm.inMonth, let view = dateViews[safe: day] else { return nil }
                    view.layoutSubtreeIfNeeded()
                    return view.frame.insetBy(dx: -inset, dy: -inset)
                }

                guard let points = CGPath.union(from: frames)?.points() else { return nil }

                return CGPath.rounded(from: points, radius: Constants.cornerRadius)
            }
            .bind(to: outlineLayer.rx.path)
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
    static let cornerRadius: CGFloat = 6
    static let outlineWidth: CGFloat = 1.5
    static let outlineInset: CGFloat = 1
}

private enum Colors {
    static var outlineBackground: CGColor { NSColor.secondaryLabelColor.effectiveCGColor }
    static var weekendBackground: CGColor { NSColor.quaternaryLabelColor.effectiveCGColor }
}

private extension CGPath {

    static func union(from rects: [CGRect]) -> CGPath? {

        guard let firstFrame = rects.first else { return nil }

        var combined = CGPath(rect: firstFrame, transform: nil)
        for frame in rects.dropFirst() {
            combined = combined.union(CGPath(rect: frame, transform: nil))
        }

        return combined
    }

    func points() -> [CGPoint] {
        var points: [CGPoint] = []

        applyWithBlock { element in
            switch element.pointee.type {
                case .moveToPoint, .addLineToPoint:
                    points.append(element.pointee.points[0])
                default:
                    break
            }
        }

        return points
    }

    static func rounded(
        from points: [CGPoint],
        radius: CGFloat
    ) -> CGPath {
        guard points.count >= 3 else { return CGPath(rect: .zero, transform: nil) }

        let path = CGMutablePath()

        let count = points.count

        func normalize(_ v: CGVector) -> CGVector {
            let len = sqrt(v.dx * v.dx + v.dy * v.dy)
            return CGVector(dx: v.dx / len, dy: v.dy / len)
        }

        for i in 0..<count {
            let prev = points[(i - 1 + count) % count]
            let curr = points[i]
            let next = points[(i + 1) % count]

            let vIn = normalize(CGVector(dx: curr.x - prev.x, dy: curr.y - prev.y))
            let vOut = normalize(CGVector(dx: next.x - curr.x, dy: next.y - curr.y))

            let start = curr - CGVector(dx: vIn.dx * radius, dy: vIn.dy * radius)
            let end = curr + CGVector(dx: vOut.dx * radius, dy: vOut.dy * radius)

            if i == 0 {
                path.move(to: start)
            } else {
                path.addLine(to: start)
            }

            path.addArc(
                tangent1End: curr,
                tangent2End: end,
                radius: radius
            )
        }

        path.closeSubpath()
        return path
    }

}

private func + (p: CGPoint, v: CGVector) -> CGPoint {
    CGPoint(x: p.x + v.dx, y: p.y + v.dy)
}

private func - (p: CGPoint, v: CGVector) -> CGPoint {
    CGPoint(x: p.x - v.dx, y: p.y - v.dy)
}
