//
//  SearchSuggestionView.swift
//  Calendr
//
//  Created by Paker on 18/12/2024.
//

import Cocoa

class SearchSuggestionView: NSStackView {
    let textField = Label()

    init() {
        super.init(frame: .zero)

        orientation = .horizontal
        alignment = .centerY
        edgeInsets = .init(horizontal: 8, vertical: 5)

        wantsLayer = true
        layer?.cornerRadius = 4

        textField.font = .systemFont(ofSize: 11)
        textField.textColor = .labelColor

        let icon = NSImage(systemName: "return").with(pointSize: 8)
        let imageView = NSImageView(image: icon)
        imageView.contentTintColor = .labelColor

        addArrangedSubview(textField)
        addArrangedSubview(imageView)
    }

    override func updateLayer() {
        super.updateLayer()
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.5).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
