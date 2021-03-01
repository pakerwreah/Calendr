//
//  CalendarPickerViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import RxSwift
import RxCocoa

class CalendarPickerViewController: NSViewController {

    private let disposeBag = DisposeBag()

    private let viewModel: CalendarPickerViewModel

    private let contentStackView = NSStackView(.vertical)

    init(viewModel: CalendarPickerViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpBindings()
    }

    override func loadView() {

        view = NSView()

        view.addSubview(contentStackView)

        contentStackView.edges(to: view)
        contentStackView.alignment = .left
    }

    private func setUpBindings() {

        viewModel.calendars
            .observe(on: MainScheduler.instance)
            .compactMap { [weak self] calendars -> [NSView]? in
                guard let self = self else { return nil }

                return Dictionary(grouping: calendars, by: { $0.account })
                    .sorted(by: { $0.key < $1.key })
                    .flatMap { account, calendars in
                        self.makeCalendarSection(title: account, calendars: calendars)
                    }
            }
            .bind(to: contentStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }
    
    private func makeCalendarSection(title: String, calendars: [CalendarModel]) -> [NSView] {

        let label = Label(text: title, font: .systemFont(ofSize: 11, weight: .semibold))
        label.textColor = .secondaryLabelColor

        let stackView = NSStackView(
            views: calendars.compactMap(makeCalendarItem)
        )
        .with(orientation: .vertical)
        .with(alignment: .left)

        return [label, NSStackView(views: [.dummy, stackView])]
    }

    private func makeCalendarItem(_ calendar: CalendarModel) -> NSView {

        let checkbox = Checkbox(title: calendar.title)
        checkbox.setTitleColor(color: NSColor(cgColor: calendar.color)!)

        viewModel.enabledCalendars
            .map { $0.contains(calendar.identifier) ? .on : .off }
            .bind(to: checkbox.rx.state)
            .disposed(by: disposeBag)

        checkbox.rx.tap
            .map { calendar.identifier }
            .bind(to: viewModel.toggleCalendar)
            .disposed(by: disposeBag)

        return checkbox
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
