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

        let label = Label(text: title, font: .systemFont(ofSize: 13, weight: .semibold))

        let divider: NSView = .spacer(height: 1)
        divider.wantsLayer = true

        divider.rx.updateLayer
            .map { NSColor.tertiaryLabelColor.effectiveCGColor }
            .bind(to: divider.layer!.rx.backgroundColor)
            .disposed(by: disposeBag)

        let stackView = NSStackView(views: [
            label,
            divider,
            NSStackView(views: [.dummy, content, .dummy])
        ])
        .with(orientation: .vertical)
        .with(alignment: .left)
        .with(spacing: 6)
        .with(spacing: 12, after: divider)

        return stackView
    }
}

enum SettingsUIConstants {

    static let contentSpacing: CGFloat = 24
}
