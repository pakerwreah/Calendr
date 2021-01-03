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
    private let headerViewModel: CalendarHeaderViewModel
    private let calendarViewModel: CalendarViewModel

    // -
    private let (clickObserver, clickObservable) = PublishSubject<Date>.pipe()
    private let (initialDateObserver, initialDateObservable) = PublishSubject<Date>.pipe()
    private let (selectedDateObserver, selectedDateObservable) = PublishSubject<Date>.pipe()

    private let calendarService = CalendarServiceProvider()

    private let disposeBag = DisposeBag()

    init() {
        headerViewModel = CalendarHeaderViewModel(dateObservable: selectedDateObservable)
        calendarHeaderView = CalendarHeaderView(viewModel: headerViewModel)

        let (hoverObserver, hoverObservable) = PublishSubject<(date: Date, isHovered: Bool)>.pipe()

        calendarViewModel = CalendarViewModel(dateObservable: selectedDateObservable,
                                              hoverObservable: hoverObservable,
                                              calendarService: calendarService)

        calendarView = CalendarView(viewModel: calendarViewModel,
                                    hoverObserver: hoverObserver,
                                    clickObserver: clickObserver)

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
        makeDateSelector()
            .asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .bind(to: selectedDateObserver)
            .disposed(by: disposeBag)

        Observable.merge(
            rx.sentMessage(#selector(NSViewController.viewDidLoad)),
            rx.sentMessage(#selector(NSViewController.viewWillAppear)),
            rx.sentMessage(#selector(NSViewController.viewDidDisappear))
        )
        .toVoid()
        .map { Date() }
        .bind(to: initialDateObserver)
        .disposed(by: disposeBag)

        clickObservable
            .bind(to: selectedDateObserver)
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
            initial: initialDateObservable,
            selected: selectedDateObservable,
            reset: headerViewModel.resetBtnObservable,
            prevDay: keyLeftObservable,
            nextDay: keyRightObservable,
            prevWeek: keyUpObservable,
            nextWeek: keyDownObservable,
            prevMonth: headerViewModel.prevBtnObservable,
            nextMonth: headerViewModel.nextBtnObservable
        )

        return dateSelector
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
