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

        viewModel.calendars
            .observe(on: MainScheduler.instance)
            .compactMap { [weak self] calendars -> [NSView]? in
                guard let self = self else { return nil }

                return Dictionary(grouping: calendars, by: { $0.account })
                    .sorted(by: \.key.localizedLowercase)
                    .flatMap { account, calendars in
                        self.makeCalendarSection(
                            title: account,
                            calendars: calendars.sorted(by: \.title.localizedLowercase)
                        )
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
        checkbox.setTitleColor(color: calendar.color)

        viewModel.enabledCalendars
            .map { $0.contains(calendar.identifier) ? .on : .off }
            .bind(to: checkbox.rx.state)
            .disposed(by: disposeBag)

        checkbox.rx.tap
            .bind { [viewModel] in
                viewModel.toggleCalendar.onNext(calendar.identifier)
            }
            .disposed(by: disposeBag)

        return checkbox
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
