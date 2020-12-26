//
//  HeaderCellView.swift
//  Calendr
//
//  Created by Paker on 26/12/20.
//

import Cocoa

class HeaderCellView: NSView {
    
    private let label = Label()

    init(viewModel: HeaderCellViewModel) {
        super.init(frame: .zero)

        forAutoLayout()

        configureLayout()

        setUpBindings(with: viewModel)
    }

    private func configureLayout() {
        addSubview(label)
        label.alignment = .center
        label.textColor = .lightGray
        label.font = .boldSystemFont(ofSize: 11)
        label
            .center(in: self)
            .size(equalTo: CGSize(width: 24, height: 13))
    }

    private func setUpBindings(with viewModel: HeaderCellViewModel) {
        label.string = viewModel.text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
