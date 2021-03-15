//
//  EventDetailsViewController.swift
//  Calendr
//
//  Created by Paker on 11/03/2021.
//

import Cocoa
import RxSwift

class EventDetailsViewController: NSViewController, NSPopoverDelegate {

    private let disposeBag = DisposeBag()

    private let _title = Label()
    private let url = Label()
    private let location = Label()
    private let duration = Label()
    private let notes = Label()

    private var fields: [Label] {
        [_title, url, location, duration, notes]
    }

    private let viewModel: EventDetailsViewModel

    init(viewModel: EventDetailsViewModel) {

        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)

        setUpBindings()
    }

    override func loadView() {
        view = NSView()

        view.widthAnchor.constraint(lessThanOrEqualToConstant: 300).activate()

        let contentStackView = NSStackView(
            views: fields
                .enumerated()
                .map { index, field in
                    index > 0
                        ? NSStackView(views: [makeLine(), field]).with(orientation: .vertical)
                        : field
                }
        )
        .with(orientation: .vertical)

        view.addSubview(contentStackView)

        contentStackView.edges(to: view, constant: 12)

        for field in fields {
            field.textColor = .labelColor
            field.lineBreakMode = .byWordWrapping
            field.isSelectable = true
        }

        _title.forceVibrancy = false
        _title.textColor = .headerTextColor
        _title.font = .header

        location.font = .small
        url.font = .small
        duration.font = .default
    }

    override func viewDidLoad() {

        _title.stringValue = viewModel.title
        url.stringValue = viewModel.url
        location.stringValue = viewModel.location
        duration.stringValue = viewModel.duration

        if ["<", ">"].allSatisfy(viewModel.notes.contains),
           let html = viewModel.notes.html(font: .default, color: .labelColor) {
            notes.attributedStringValue = html
        } else {
            notes.font = .default
            notes.stringValue = viewModel.notes
        }

        for field in fields {
            field.superview?.isHidden = field.isEmpty
        }
    }

    private func setUpBindings() {

        let popoverView = view.rx.observe(\.superview)
            .compactMap { $0 as? NSVisualEffectView }
            .take(1)

        Observable.combineLatest(
            popoverView, viewModel.popoverMaterial
        )
        .bind { $0.material = $1 }
        .disposed(by: disposeBag)
    }

    func popoverWillClose(_ notification: Notification) {
        // 🔨 Fix a bug when selecting some text and closing the popover
        // causes the resignFirstResponder to go crazy and doesn't select anymore
        view.window?.makeFirstResponder(nil)
    }

    private func makeLine() -> NSView {

        let line = NSView.spacer(height: 1)
        line.wantsLayer = true

        line.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.cgColor }
            .bind(to: line.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        return line
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


private extension NSFont {

    static let `default` = systemFont(ofSize: 13)
    static let header = systemFont(ofSize: 16)
    static let small = systemFont(ofSize: 12)
}
