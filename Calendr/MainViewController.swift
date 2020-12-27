//
//  MainViewController.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa
import RxSwift
import RxCocoa

class MainViewController: NSViewController {

    private let mainStackView = NSStackView(.vertical)
    private let monthSelectorView: MonthSelectorView
    private let calendarView: CalendarView

    private let monthSelectorViewModel: MonthSelectorViewModel
    private let calendarViewModel: CalendarViewModel

    private let dateSubject = BehaviorSubject<Date>(value: Date())

    private let disposeBag = DisposeBag()

    init() {
        let dateObservable = dateSubject.asObservable()

        monthSelectorViewModel = MonthSelectorViewModel(dateObservable: dateObservable)
        monthSelectorView = MonthSelectorView(viewModel: monthSelectorViewModel)

        calendarViewModel = CalendarViewModel(dateObservable: dateObservable)
        calendarView = CalendarView(viewModel: calendarViewModel)

        super.init(nibName: nil, bundle: nil)

        setUpBindings()
    }

    override func loadView() {
        view = NSView()

        view.addSubview(mainStackView)

        mainStackView.spacing = 4
        mainStackView.edges(to: view, constant: 8)

        mainStackView.addArrangedSubview(monthSelectorView)
        mainStackView.addArrangedSubview(calendarView)
    }

    func setUpBindings() {
        monthSelectorViewModel
            .prevBtnSubject
            .withLatestFrom(dateSubject)
            .map { Calendar.current.date(byAdding: .month, value: -1, to: $0)! }
            .bind(to: dateSubject)
            .disposed(by: disposeBag)

        monthSelectorViewModel
            .nextBtnSubject
            .withLatestFrom(dateSubject)
            .map { Calendar.current.date(byAdding: .month, value: 1, to: $0)! }
            .bind(to: dateSubject)
            .disposed(by: disposeBag)

        monthSelectorViewModel
            .todayBtnSubject
            .map { Date() }
            .bind(to: dateSubject)
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
