//
//  CalendarListViewController.swift
//  Calendr
//
//  Created by Paker on 28/01/21.
//

import Cocoa
import RxSwift

enum CalendarListSource {
    case settings
    case menu
}

class CalendarListViewController: NSViewController, SettingsUI {

    private let pickerDisposeBag = DisposeBag()
    private var itemsDisposeBag: DisposeBag!

    private let viewModel: CalendarListViewModel

    private let contentStackView = NSStackView(.vertical)

    private let source: CalendarListSource

    init(viewModel: CalendarListViewModel, source: CalendarListSource) {

        self.viewModel = viewModel
        self.source = source

        super.init(nibName: nil, bundle: nil)

        setUpBindings()
    }

    override func viewDidLoad() {

        super.viewDidLoad()

        let scrollView = NSScrollView()

        view.addSubview(scrollView)

        scrollView.edges(equalTo: view, margins: source.margins)

        scrollView.drawsBackground = false
        scrollView.documentView = contentStackView.forAutoLayout()

        scrollView.contentView.edges(equalTo: scrollView)
        scrollView.contentView.top(equalTo: contentStackView)
        scrollView.contentView.leading(equalTo: contentStackView)
        scrollView.contentView.trailing(equalTo: contentStackView)
        let height = scrollView.contentView.height(equalTo: contentStackView)

        switch source {

            case .settings:
                height.priority = .dragThatCanResizeWindow
                scrollView.contentView.height(lessThanOrEqualTo: 600)

            case .menu:
                view.width(equalTo: 250)
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

                return calendars.groupedByAccount()
                    .map { section in
                        self.makeCalendarSection(
                            title: section.account.title,
                            calendars: section.calendars,
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
                    let calendarItem = makeCalendarItem($0)
                    return NSStackView(
                        views: [
                            .dummy,
                            calendarItem,
                            $0.isSubscribed ? makeCalendarItemSubscribedIcon() : nil,
                            .spacer,
                            showNextEvent ? makeCalendarItemNextEvent($0) : nil,
                            makeCalendarItemSettingsButton($0)
                        ]
                        .compact()
                    )
                    .with(alignment: .centerY)
                    .with(spacing: 4, after: calendarItem)
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

    private func makeCalendarItem(_ calendar: CalendarModel) -> NSView {

        let checkbox = Checkbox(title: calendar.title)
        checkbox.setContentHuggingPriority(.required, for: .horizontal)
        checkbox.setContentCompressionResistancePriority(.required, for: .horizontal)

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

    private func makeCalendarItemSubscribedIcon() -> NSView {
        let imageView = NSImageView(image: Icons.CalendarList.subscribed.with(scale: .small))
        imageView.contentTintColor = .secondaryLabelColor
        return imageView
    }

    private func makeCalendarItemNextEvent(_ calendar: CalendarModel) -> NSView {

        let selectedIcon = Icons.CalendarList.nextEventEnabled.with(pointSize: 11)
        let unselectedIcon = Icons.CalendarList.nextEventSilenced.with(pointSize: 11)
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

    private func makeCalendarItemSettingsButton(_ calendar: CalendarModel) -> NSView? {
        // FIXME: For some reason, dropdowns don't work when presented from a popover
        //        so we have to restrict this feature to the settings window only
        guard source == .settings else { return nil }

        let button = ImageButton(image: Icons.CalendarList.settings.with(pointSize: 12))
        button.contentTintColor = .textColor

        let calendarSettingsViewModel = viewModel.calendarSettingsViewModel(for: calendar)

        button.rx.tap
            .bind { [weak self] in
                self?.presentAsSheet(
                    CalendarSettingsViewController(
                        viewModel: calendarSettingsViewModel
                    )
                )
            }
            .disposed(by: itemsDisposeBag)

        return button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Extensions

extension CalendarListSource {

    var margins: NSEdgeInsets {
        switch self {
        case .settings:
            return .init()
        case .menu:
            return .init(top: 16, left: 16, bottom: 16, right: 20)
        }
    }
}
