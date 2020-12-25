//
//  CalendarView.swift
//  Calendr
//
//  Created by Paker on 24/12/20.
//

import Cocoa
import RxSwift

class CalendarView: NSView {

    private let cellSize: CGFloat = 30
    private let gridView = NSGridView(numberOfColumns: 7, rows: 6)

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
        for row in 0..<gridView.numberOfRows {
            for col in 0..<gridView.numberOfColumns {
                let dataObservable = viewModel.cellViewModelsObservable.map(\.[row][col])
                let cellView = CalendarCellView(dataObservable: dataObservable)
                gridView.cell(atColumnIndex: col, rowIndex: row).contentView = cellView
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
