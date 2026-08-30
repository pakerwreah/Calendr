//
//  MonthPickerViewController.swift
//  Calendr
//
//  Created by Paker on 30/08/2026.
//

import AppKit

class MonthPickerViewController: NSViewController {

    struct SelectedYearMonth {
        let year: Int
        let month: Int
    }

    var onSelect: ((SelectedYearMonth) -> Void)?

    private var updating = false

    private var selectedYear: Int = 0 {
        didSet {
            onChange()
        }
    }
    private var selectedMonth: Int = 0 {
        didSet {
            onChange()
        }
    }

    private let yearLabel = Label()
    private let stepper = NSStepper()
    private var monthButtons: [NSButton] = []

    private let dateProvider: DateProviding

    init(dateProvider: DateProviding) {

        self.dateProvider = dateProvider

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func update(with date: Date) {
        updating = true

        let components = dateProvider.calendar.dateComponents([.year, .month], from: date)
        selectedYear = components.year ?? 0
        selectedMonth = components.month ?? 0

        updating = false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeaderRow()
        setupMonthGrid()
        updateUI()
    }
    
    private func setupHeaderRow() {
        yearLabel.font = .systemFont(ofSize: 14, weight: .bold)

        stepper.minValue = 2000
        stepper.maxValue = 2100
        stepper.intValue = Int32(selectedYear)

        stepper.target = self
        stepper.action = #selector(yearStepperChanged(_:))

        stepper.controlSize = .small
        stepper.cell?.focusRingType = .none

        view.addSubview(yearLabel)
        view.addSubview(stepper)

        yearLabel.top(equalTo: view, constant: Constants.spacing)
        yearLabel.center(in: view, orientation: .horizontal)

        stepper.leading(equalTo: yearLabel.trailingAnchor, constant: Constants.spacing)
        stepper.center(in: yearLabel, orientation: .vertical)
    }
    
    private func setupMonthGrid() {
        let shortMonths = dateProvider.calendar.shortMonthSymbols
        let buttonSize = CGSize(width: 45, height: 35)

        let gridView = NSGridView(numberOfColumns: 4, rows: 3)
        gridView.xPlacement = .fill
        gridView.yPlacement = .fill
        gridView.rowSpacing = 0
        gridView.columnSpacing = 0

        view.addSubview(gridView)

        gridView.top(equalTo: yearLabel.bottomAnchor, constant: Constants.spacing)
        gridView.leading(equalTo: view, constant: Constants.spacing)
        gridView.trailing(equalTo: view, constant: -Constants.spacing)
        gridView.bottom(equalTo: view, constant: -Constants.spacing)

        for index in 0..<12 {
            let row = index / 4
            let col = index % 4
            
            let btn = NSButton()
            btn.focusRingType = .none
            btn.title = shortMonths[index]
            btn.setButtonType(.pushOnPushOff)
            btn.bezelStyle = .flexiblePush
            btn.showsBorderOnlyWhileMouseInside = true
            btn.tag = index + 1
            btn.target = self
            btn.action = #selector(monthClicked(_:))

            let cell = gridView.cell(atColumnIndex: col, rowIndex: row)
            cell.column?.width = buttonSize.width
            cell.row?.height = buttonSize.height
            cell.contentView = btn

            monthButtons.append(btn)
        }
    }
    
    private func updateUI() {
        yearLabel.stringValue = "\(selectedYear)"
        stepper.intValue = Int32(selectedYear)
        
        for btn in monthButtons {
            let isSelected = btn.tag == selectedMonth
            btn.state = isSelected ? .on : .off
            btn.bezelColor = isSelected ? .controlAccentColor : nil
        }
    }

    private func onChange() {
        updateUI()
        if !updating {
            onSelect?(.init(year: selectedYear, month: selectedMonth))
        }
    }

    @objc private func yearStepperChanged(_ sender: NSStepper) {
        selectedYear = Int(sender.intValue)
    }
    
    @objc private func monthClicked(_ sender: NSButton) {
        selectedMonth = sender.tag
        view.enclosingMenuItem?.menu?.cancelTracking()
    }
}

private enum Constants {
    static let spacing: CGFloat = 8
}
