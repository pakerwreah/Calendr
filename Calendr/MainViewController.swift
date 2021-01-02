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

    // Views
    private let mainStackView = NSStackView(.vertical)
    private let calendarHeaderView: CalendarHeaderView
    private let calendarView: CalendarView

    // ViewModels
    private let calendarHeaderViewModel: CalendarHeaderViewModel
    private let calendarViewModel: CalendarViewModel

    // -
    private lazy var dateSelector = makeDateSelector()
    private let initialDateSubject = PublishSubject<Date>()
    private let selectedDateSubject = PublishSubject<Date>()
    private let calendarService = CalendarServiceProvider()

    private let disposeBag = DisposeBag()

    init() {
        calendarHeaderViewModel = CalendarHeaderViewModel(dateObservable: selectedDateSubject)
        calendarHeaderView = CalendarHeaderView(viewModel: calendarHeaderViewModel)

        calendarViewModel = CalendarViewModel(dateObservable: selectedDateSubject, calendarService: calendarService)
        calendarView = CalendarView(viewModel: calendarViewModel)

        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        view = NSView()

        view.addSubview(mainStackView)

        mainStackView.spacing = 4
        mainStackView.edges(to: view, constant: 8)

        mainStackView.addArrangedSubview(calendarHeaderView)
        mainStackView.addArrangedSubview(calendarView)
    }

    override func viewDidLoad() {
        setUpBindings()

        calendarService.requestAccess()
    }

    private func setUpBindings() {
        dateSelector
            .asObservable()
            .bind(to: selectedDateSubject)
            .disposed(by: disposeBag)

        Observable.merge(
            rx.sentMessage(#selector(NSViewController.viewDidLoad)),
            rx.sentMessage(#selector(NSViewController.viewWillAppear)),
            rx.sentMessage(#selector(NSViewController.viewDidDisappear))
        )
        .toVoid()
        .map { Date() }
        .bind(to: initialDateSubject)
        .disposed(by: disposeBag)
    }

    private func makeDateSelector() -> DateSelector {

        let keyObservable = rx.sentMessage(#selector(NSViewController.keyUp(with:)))
            .compactMap { $0.first as? NSEvent }
            .map(\.keyCode)
            .share()

        let keyLeftObservable = keyObservable.filter { $0 == 123 }.toVoid()
        let keyRightObservable = keyObservable.filter { $0 == 124 }.toVoid()
        let keyDownObservable = keyObservable.filter { $0 == 125 }.toVoid()
        let keyUpObservable = keyObservable.filter { $0 == 126 }.toVoid()

        let dateSelector = DateSelector(
            initial: initialDateSubject,
            reset: calendarHeaderView.resetBtnObservable,
            prevDay: keyLeftObservable,
            nextDay: keyRightObservable,
            prevWeek: keyUpObservable,
            nextWeek: keyDownObservable,
            prevMonth: calendarHeaderView.prevBtnObservable,
            nextMonth: calendarHeaderView.nextBtnObservable
        )

        return dateSelector
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
