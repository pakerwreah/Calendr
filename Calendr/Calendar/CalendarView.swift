//
//  CalendarView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class CalendarView: NSView {

    private let cellSize: CGFloat = 25
    private let gridView = NSGridView(numberOfColumns: 7, rows: 7)

    private let disposeBag = DisposeBag()

    init(viewModel: CalendarViewModel) {
        super.init(frame: .zero)

        configureLayout()

        setUpBindings(with: viewModel)
    }

    private func configureLayout() {
        gridView.xPlacement = .fill
        gridView.yPlacement = .fill
        gridView.rowSpacing = 0
        gridView.columnSpacing = 0

        for row in 0..<gridView.numberOfRows {
            gridView.row(at: row).height = cellSize
            for col in 0..<gridView.numberOfColumns {
                gridView.column(at: col).width = cellSize
            }
        }

        addSubview(gridView)

        gridView.edges(to: self)
    }

    private func setUpBindings(with viewModel: CalendarViewModel) {
        for day in 0..<7 {
            let viewModel = HeaderCellViewModel(day: day)
            let cellView = HeaderCellView(viewModel: viewModel)
            gridView.cell(atColumnIndex: day, rowIndex: 0).contentView = cellView
        }

        for day in 0..<42 {
            let viewModel = viewModel.asObservable().map(\.[day])
            let cellView = CalendarCellView(viewModel: viewModel)
            gridView.cell(atColumnIndex: day % 7, rowIndex: 1 + day / 7).contentView = cellView
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
