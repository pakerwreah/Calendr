//
//  EventView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import RxCocoa
import RxSwift

class EventView: NSView {

    private let disposeBag = DisposeBag()

    private let viewModel: EventViewModel

    private let title = Label()
    private let duration = Label()
    private let progress = NSView()

    private lazy var progressTop: NSLayoutConstraint = {
        progress.topAnchor.constraint(equalTo: topAnchor)
    }()

    init(viewModel: EventViewModel) {

        self.viewModel = viewModel

        super.init(frame: .zero)

        configureLayout()

        setUpBindings()

        setData()
    }

    private func setData() {

        title.stringValue = viewModel.title
        duration.stringValue = viewModel.duration
        duration.isHidden = viewModel.duration.isEmpty

        if viewModel.isPending {
            layer?.backgroundFilters = Self.pendingBackgroundFilters
        }
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        layer?.cornerRadius = 2

        title.lineBreakMode = .byWordWrapping
        title.textColor = .headerTextColor
        title.font = .systemFont(ofSize: 12)

        duration.lineBreakMode = .byWordWrapping
        duration.textColor = .secondaryLabelColor
        duration.font = .systemFont(ofSize: 11)

        let colorBar = NSView()
        colorBar.wantsLayer = true
        colorBar.layer?.backgroundColor = viewModel.color
        colorBar.layer?.cornerRadius = 2
        colorBar.width(equalTo: 4)

        let eventStackView = NSStackView(.vertical)
        eventStackView.spacing = 2
        eventStackView.addArrangedSubviews(title, duration)

        let contentStackView = NSStackView(.horizontal)
        addSubview(contentStackView)
        contentStackView.edges(to: self)
        contentStackView.addArrangedSubviews(colorBar, eventStackView)

        addSubview(progress, positioned: .below, relativeTo: nil)

        progress.wantsLayer = true
        progress.layer?.backgroundColor = NSColor.red.cgColor

        progress
            .height(equalTo: 0.5)
            .width(equalTo: self)

        progressTop.isActive = true
    }

    private func setUpBindings() {

        viewModel.isFaded
            .map { $0 ? 0.5 : 1 }
            .bind(to: rx.alpha)
            .disposed(by: disposeBag)

        Observable.combineLatest(
            viewModel.progress, rx.observe(\.frame)
        )
        .compactMap { progress, frame in
            progress.map { max(1, $0 * frame.height - 0.5) }
        }
        .bind(to: progressTop.rx.constant)
        .disposed(by: disposeBag)

        viewModel.isLineVisible
            .map(\.isFalse)
            .bind(to: progress.rx.isHidden)
            .disposed(by: disposeBag)

        viewModel.backgroundColor
            .bind(to: layer!.rx.backgroundColor)
            .disposed(by: disposeBag)
    }

    private static let pendingBackgroundFilters: [CIFilter] = {
        let stripes = CIFilter(name: "CIStripesGenerator", parameters: [
            "inputColor0": CIColor(color: NSColor.gray.withAlphaComponent(0.25))!,
            "inputColor1": CIColor.clear,
            "inputWidth": 2.5,
            "inputSharpness" : 0
        ])!

        let rotated = CIFilter(name: "CIAffineTransform", parameters: [
            "inputTransform": CGAffineTransform(rotationAngle: -.pi / 4)
        ])!

        return [stripes, rotated]
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
