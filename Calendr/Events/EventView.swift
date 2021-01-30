//
//  EventView.swift
//  Calendr
//
//  Created by Paker on 23/01/21.
//

import RxCocoa
import RxSwift
import CoreImage.CIFilterBuiltins

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
            layer?.backgroundColor = Self.pendingBackground
        }
    }

    private func configureLayout() {

        forAutoLayout()

        wantsLayer = true
        layer?.cornerRadius = 2

        title.forceVibrancy = false
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
        progress.layer?.backgroundColor = NSColor.red.cgColor.copy(alpha: 0.5)

        progress
            .height(equalTo: 1)
            .width(equalTo: self)

        progressTop.isActive = true
    }

    private func setUpBindings() {

        viewModel.isFaded
            .map { $0 ? 0.5 : 1 }
            .bind(to: rx.alpha)
            .disposed(by: disposeBag)

        viewModel.isHidden
            .bind(to: rx.isHidden)
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

    private static let pendingBackground: CGColor = {

        let stripes = CIFilter.stripesGenerator()
        stripes.color0 = CIColor(color: NSColor.gray.withAlphaComponent(0.25))!
        stripes.color1 = .clear
        stripes.width = 2.5
        stripes.sharpness = 0

        let rotated = CIFilter.affineClamp()
        rotated.inputImage = stripes.outputImage!
        rotated.transform = CGAffineTransform(rotationAngle: -.pi / 4)

        let ciImage = rotated.outputImage!.cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        return NSColor(patternImage: nsImage).cgColor
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
