//
//  CalendarPickerViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import Cocoa
import RxSwift

enum CalendarPickerConfiguration {
    case settings
    case picker
}

class CalendarPickerViewController: NSViewController {

    private let pickerDisposeBag = DisposeBag()
    private var itemsDisposeBag: DisposeBag!

    private let viewModel: CalendarPickerViewModel

    private let contentStackView = NSStackView(.vertical)

    private let configuration: CalendarPickerConfiguration

    init(viewModel: CalendarPickerViewModel, configuration: CalendarPickerConfiguration) {

        self.viewModel = viewModel
        self.configuration = configuration

        super.init(nibName: nil, bundle: nil)

        setUpAccessibility()

        setUpBindings()
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(configuration.accessibilityIdentifier)
    }

    override func loadView() {

        view = NSView()

        let scrollView = NSScrollView()

        view.addSubview(scrollView)

        scrollView.edges(equalTo: view, margins: configuration.margins)

        scrollView.drawsBackground = false
        scrollView.documentView = contentStackView.forAutoLayout()

        scrollView.contentView.edges(equalTo: scrollView)
        scrollView.contentView.top(equalTo: contentStackView)
        scrollView.contentView.leading(equalTo: contentStackView)
        scrollView.contentView.trailing(equalTo: contentStackView)
        let height = scrollView.contentView.height(equalTo: contentStackView)

        if configuration ~= .settings {
            height.priority = .dragThatCanResizeWindow
            scrollView.contentView.height(lessThanOrEqualTo: 600)
        }

        contentStackView.spacing = 16
    }

    private func setUpBindings() {

        Observable
            .combineLatest(
                viewModel.calendars,
                viewModel.showNextEvent
            )
            .observe(on: MainScheduler.instance)
            .compactMap { [weak self] calendars, showNextEvent -> [NSView]? in
                guard let self else { return nil }

                itemsDisposeBag = DisposeBag()

                func isOther(_ account: String) -> Bool {
                    account == Strings.Calendars.Source.others
                }

                return Dictionary(grouping: calendars, by: { $0.account })
                    .sorted {
                        if isOther($0.key) && !isOther($1.key) {
                            return false // $0 is Other, so it should go down
                        }
                        if !isOther($0.key) && isOther($1.key) {
                            return true // $1 is Other, so it should go down
                        }
                        return $0.key.localizedLowercase < $1.key.localizedLowercase // Otherwise, sort by name
                    }
                    .map { account, calendars in
                        self.makeCalendarSection(
                            title: account,
                            calendars: calendars.sorted(by: \.title.localizedLowercase),
                            showNextEvent: showNextEvent
                        )
                    }
            }
            .bind(to: contentStackView.rx.arrangedSubviews)
            .disposed(by: pickerDisposeBag)
    }
    
    private func makeCalendarSection(title: String, calendars: [CalendarModel], showNextEvent: Bool) -> NSView {

        let label = Label(text: title, font: .systemFont(ofSize: 11, weight: .semibold))
        label.textColor = .secondaryLabelColor

        let stackView = NSStackView(
            views: [
                [label],
                calendars.compactMap {
                    NSStackView(
                        views: [
                            .dummy,
                            makeCalendarItemEnabled($0),
                            showNextEvent ? makeCalendarItemNextEvent($0) : nil
                        ]
                        .compact()
                    )
                    .with(alignment: .centerY)
                }
            ].flatten()
        ).with(orientation: .vertical)

        return stackView
    }

    private func bindCalendarItem(
        button: NSButton,
        identifier: String,
        selected: Observable<[String]>,
        toggle: AnyObserver<String>
    ) {
        selected
            .map { $0.contains(identifier) ? .on : .off }
            .bind(to: button.rx.state)
            .disposed(by: itemsDisposeBag)

        button.rx.click
            .bind { toggle.onNext(identifier) }
            .disposed(by: itemsDisposeBag)
    }

    private func makeCalendarItemEnabled(_ calendar: CalendarModel) -> NSView {

        let checkbox = Checkbox(title: calendar.title)

        Scaling.observable.bind {
            checkbox.setTitleColor(color: calendar.color, font: .systemFont(ofSize: 13 * $0))
        }
        .disposed(by: itemsDisposeBag)

        bindCalendarItem(
            button: checkbox,
            identifier: calendar.id,
            selected: viewModel.enabledCalendars,
            toggle: viewModel.toggleCalendar
        )

        return checkbox
    }

    private func makeCalendarItemNextEvent(_ calendar: CalendarModel) -> NSView {

        let selectedIcon = Icons.CalendarPicker.nextEventSelected.with(pointSize: 11)
        let unselectedIcon = Icons.CalendarPicker.nextEventUnselected.with(pointSize: 11)
        let button = ImageButton()
        button.setButtonType(.toggle)

        view.rx.updateLayer
            .startWith(())
            .map { unselectedIcon.with(color: .secondaryLabelColor) }
            .bind(to: button.rx.image)
            .disposed(by: itemsDisposeBag)

        view.rx.updateLayer
            .startWith(())
            .map { selectedIcon.with(color: .textColor) }
            .bind(to: button.rx.alternateImage)
            .disposed(by: itemsDisposeBag)

        bindCalendarItem(
            button: button,
            identifier: calendar.id,
            selected: viewModel.nextEventCalendars,
            toggle: viewModel.toggleNextEvent
        )

        return button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Extensions

extension CalendarPickerConfiguration {

    var accessibilityIdentifier: String {
        switch self {
        case .settings:
            return Accessibility.Settings.Calendars.view
        case .picker:
            return Accessibility.CalendarPicker.view
        }
    }

    var margins: NSEdgeInsets {
        switch self {
        case .settings:
            return .init()
        case .picker:
            return .init(top: 16, left: 16, bottom: 16, right: 20)
        }
    }
}
