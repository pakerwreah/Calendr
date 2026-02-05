//
//  EventListSummaryView.swift
//  Calendr
//
//  Created by Paker on 26/10/2025.
//

import AppKit
import RxSwift

class EventListSummaryView: NSView {

    private let disposeBag = DisposeBag()

    init(
        summary: Observable<EventListSummary>,
        showSummary: Observable<Bool> = .just(true),
        scaling: Observable<Double> = Scaling.observable
    ) {
        super.init(frame: .zero)

        let stackView = NSStackView()
            .with(distribution: .fillEqually)
            .with(spacing: 4)
            .with(insets: .init(horizontal: 1))

        func makeColorBar(_ color: NSColor) -> NSView {
            let colorBar = NSView()
            colorBar.wantsLayer = true
            colorBar.layer?.cornerRadius = 1
            colorBar.width(equalTo: 2)
            colorBar.layer?.backgroundColor = color.cgColor
            return colorBar
        }

        func makeColorBarStack(with colors: Set<NSColor>) -> NSStackView {
            NSStackView(views: colors.map(makeColorBar)).with(spacing: 2)
        }

        func makeLabel(_ text: String) -> Label {
            let label = Label(text: text, font: .systemFont(ofSize: 10), scaling: scaling)
            label.lineBreakMode = .byWordWrapping
            label.setContentHuggingPriority(.fittingSizeCompression, for: .vertical)
            return label
        }

        func addItem(_ type: EventListSummaryType, _ item: EventListSummaryItem, _ spacing: CGFloat) {
            guard item.count > 0 else { return }
            let stack = NSStackView().with(spacing: spacing)
            let colorBars = makeColorBarStack(with: item.colors)
            let label = makeLabel("\(type.label): \(item.count)")
            stack.addArrangedSubview(colorBars)
            stack.addArrangedSubview(label)
            stackView.addArrangedSubview(stack)
        }

        Observable.combineLatest(summary, showSummary)
            .observe(on: MainScheduler.instance)
            .bind { [weak self] info, isVisible in
                stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

                let count = [info.overdue, info.allday, info.today].filter { $0.count > 0 }.count
                let spacing: CGFloat = count > 2 ? 4 : 6

                addItem(.overdue, info.overdue, spacing)
                addItem(.allday, info.allday, spacing)
                addItem(.today, info.today, spacing)

                self?.isHidden = !isVisible || stackView.arrangedSubviews.isEmpty
            }
            .disposed(by: disposeBag)

        addSubview(stackView)
        stackView.edges(equalTo: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum EventListSummaryType {
    case overdue
    case allday
    case today

    var label: String {
        switch self {
            case .overdue: Strings.Reminder.Status.overdue
            case .allday: Strings.Event.allDay
            case .today: Strings.EventList.Summary.agenda
        }
    }
}
