//
//  SettingsViewController.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import RxSwift
import RxCocoa

class SettingsViewController: NSViewController {

    private let disposeBag = DisposeBag()

    private let calendarStackView = NSStackView(.vertical)

    private let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        title = "Calendars"

        setUpBindings()
    }

    override func loadView() {
        view = NSView()

        view.addSubview(calendarStackView)

        calendarStackView.edges(to: view, constant: 16)
        calendarStackView.alignment = .left
    }

    override func viewDidAppear() {
        view.window?.styleMask.remove(.resizable)
    }

    private func setUpBindings() {

        viewModel.calendars.compactMap { [weak self] calendars -> [NSView]? in
            guard let self = self else { return nil }

            return Dictionary(grouping: calendars, by: { $0.account })
                .sorted(by: { $0.key < $1.key })
                .flatMap { account, calendars in
                    self.makeCalendarSection(title: account, calendars: calendars)
                }
        }
        .bind(to: calendarStackView.rx.arrangedSubviews)
        .disposed(by: disposeBag)

    }

    private func makeCalendarSection(title: String, calendars: [CalendarModel]) -> [NSView] {

        let label = Label(text: title, font: .boldSystemFont(ofSize: 13))

        let stackView = NSStackView(.vertical)
        stackView.alignment = .left
        stackView.addArrangedSubviews(calendars.compactMap(makeCalendarItem))

        let margin = NSView().width(equalTo: 0)

        return [label, NSStackView(views: [margin, stackView])]
    }

    private func makeCalendarItem(_ calendar: CalendarModel) -> NSView {

        let checkbox = NSButton()
        checkbox.setButtonType(.switch)
        checkbox.title = calendar.title
        checkbox.setTitleColor(color: NSColor(cgColor: calendar.color)!)
        checkbox.refusesFirstResponder = true

        viewModel.enabledCalendarsObservable.map { identifiers -> NSControl.StateValue in
            identifiers.contains(calendar.identifier) ? .on : .off
        }
        .bind(to: checkbox.rx.state)
        .disposed(by: disposeBag)

        checkbox.rx.tap
            .withLatestFrom(viewModel.enabledCalendarsObservable)
            .map { identifiers in
                checkbox.state == .on
                    ? identifiers + [calendar.identifier]
                    : identifiers.filter { $0 != calendar.identifier }
            }
            .bind(to: viewModel.enabledCalendarsObserver)
            .disposed(by: disposeBag)

        return checkbox
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
