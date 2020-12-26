//
//  MainViewController.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa

class MainViewController: NSViewController {

    private let mainStackView = NSStackView()
    private let calendarView: CalendarView

    init() {
        calendarView = CalendarView(viewModel: CalendarViewModel(yearObservable: .just(2020), monthObservable: .just(12)))

        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = NSView()

        view.addSubview(mainStackView)

        mainStackView.edges(to: view, constant: 8)

        mainStackView.addArrangedSubview(calendarView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
