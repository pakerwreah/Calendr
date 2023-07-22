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

    private let disposeBag = DisposeBag()

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

        scrollView.edges(to: view, insets: configuration.insets)

        scrollView.drawsBackground = false
        scrollView.documentView = contentStackView.forAutoLayout()

        scrollView.contentView.edges(to: scrollView)
        scrollView.contentView.top(equalTo: contentStackView)
        scrollView.contentView.leading(equalTo: contentStackView)
        scrollView.contentView.trailing(equalTo: contentStackView)
        let height = scrollView.contentView.height(equalTo: contentStackView)

        if configuration ~= .settings {
            height.priority = .dragThatCanResizeWindow
            scrollView.contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 600).activate()
        }

        contentStackView.alignment = .left
    }

    private func setUpBindings() {

        Observable
            .combineLatest(
                viewModel.calendars,
                viewModel.showNextEvent
            )
            .observe(on: MainScheduler.instance)
            .compactMap { [weak self] calendars, showNextEvent -> [NSView]? in
                guard let self = self else { return nil }

                return Dictionary(grouping: calendars, by: { $0.account })
                    .sorted(by: \.key.localizedLowercase)
                    .flatMap { account, calendars in
                        self.makeCalendarSection(
                            title: account,
                            calendars: calendars.sorted(by: \.title.localizedLowercase),
                            showNextEvent: showNextEvent
                        )
                    }
            }
            .bind(to: contentStackView.rx.arrangedSubviews)
            .disposed(by: disposeBag)
    }
    
    private func makeCalendarSection(title: String, calendars: [CalendarModel], showNextEvent: Bool) -> [NSView] {

        let label = Label(text: title, font: .systemFont(ofSize: 11, weight: .semibold))
        label.textColor = .secondaryLabelColor

        let stackView = NSStackView(
            views: calendars.compactMap {
                NSStackView(
                    views: [
                        makeCalendarItemEnabled($0),
                        showNextEvent ? makeCalendarItemNextEvent($0) : nil
                    ]
                    .compact()
                )
            }
        )
        .with(orientation: .vertical)
        .with(alignment: .left)

        return [label, NSStackView(views: [.dummy, stackView])]
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
            .disposed(by: disposeBag)

        button.rx.click
            .bind { toggle.onNext(identifier) }
            .disposed(by: disposeBag)
    }

    private func makeCalendarItemEnabled(_ calendar: CalendarModel) -> NSView {

        let checkbox = Checkbox(title: calendar.title)
        checkbox.setTitleColor(color: calendar.color)

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
            .map { unselectedIcon.with(color: .secondaryLabelColor) }
            .bind(to: button.rx.image)
            .disposed(by: disposeBag)

        view.rx.updateLayer
            .map { selectedIcon.with(color: .textColor) }
            .bind(to: button.rx.alternateImage)
            .disposed(by: disposeBag)

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

    var insets: NSEdgeInsets {
        switch self {
        case .settings:
            return .init()
        case .picker:
            return .init(top: 16, left: 16, bottom: 16, right: 20)
        }
    }
}
