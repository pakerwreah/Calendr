//
//  SettingsUI.swift
//  Calendr
//
//  Created by Paker on 20/07/24.
//

import Cocoa
import RxSwift

protocol SettingsUI {
    typealias Constants = SettingsUIConstants

    var disposeBag: DisposeBag { get }
}

extension SettingsUI {
    
    func makeSection(title: String, content: NSView) -> NSView {

        let label = Label(text: title, font: .systemFont(ofSize: 16, weight: .semibold))

        let divider: NSView = .spacer(height: 1)
        divider.wantsLayer = true

        divider.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.effectiveCGColor }
            .bind(to: divider.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        let stackView = NSStackView(views: [
            label,
            divider,
            content
        ])
        .with(orientation: .vertical)
        .with(spacing: 6)
        .with(spacing: 12, after: divider)

        stackView.setHuggingPriority(.required, for: .horizontal)

        return stackView
    }
}

enum SettingsUIConstants {

    static let contentSpacing: CGFloat = 24
}
