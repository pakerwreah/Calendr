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
    private let calendarHeaderView: CalendarHeaderView
    private let calendarView: CalendarView

    private let calendarHeaderViewModel: CalendarHeaderViewModel
    private let calendarViewModel: CalendarViewModel

    private let calendarService = CalendarServiceProvider()

    private let dateSubject = BehaviorSubject<Date>(value: Date())

    private let disposeBag = DisposeBag()

    init() {
        let dateObservable = dateSubject.asObservable()

        calendarHeaderViewModel = CalendarHeaderViewModel(dateObservable: dateObservable)
        calendarHeaderView = CalendarHeaderView(viewModel: calendarHeaderViewModel)

        calendarViewModel = CalendarViewModel(dateObservable: dateObservable, calendarService: calendarService)
        calendarView = CalendarView(viewModel: calendarViewModel)

        super.init(nibName: nil, bundle: nil)

        setUpBindings()

        calendarService.requestAccess()
    }

    override func loadView() {
        view = NSView()

        view.addSubview(mainStackView)

        mainStackView.spacing = 4
        mainStackView.edges(to: view, constant: 8)

        mainStackView.addArrangedSubview(calendarHeaderView)
        mainStackView.addArrangedSubview(calendarView)
    }

    func setUpBindings() {
        let resetObservable = Observable.merge(
            rx.sentMessage(#selector(NSViewController.viewWillAppear)).toVoid(),
            calendarHeaderView.resetBtnObservable
        )

        let keyObservable = rx.sentMessage(#selector(NSViewController.keyUp(with:)))
            .compactMap { $0.first as? NSEvent }
            .map(\.keyCode)
            .share()

        let keyLeftObservable = keyObservable.filter { $0 == 123 }.toVoid()
        let keyRightObservable = keyObservable.filter { $0 == 124 }.toVoid()
        let keyDownObservable = keyObservable.filter { $0 == 125 }.toVoid()
        let keyUpObservable = keyObservable.filter { $0 == 126 }.toVoid()

        DateSelector(
            initial: dateSubject,
            reset: resetObservable,
            prevDay: keyLeftObservable,
            nextDay: keyRightObservable,
            prevWeek: keyUpObservable,
            nextWeek: keyDownObservable,
            prevMonth: calendarHeaderView.prevBtnObservable,
            nextMonth: calendarHeaderView.nextBtnObservable
        )
        .asObservable()
        .bind(to: dateSubject)
        .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
