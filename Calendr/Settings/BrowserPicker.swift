//
//  BrowserPicker.swift
//  Calendr
//
//  Created by Paker on 02/08/2026.
//

import AppKit
import RxSwift

class BrowserPicker: NSView {

    private let dropdown = Dropdown()

    private let disposeBag = DisposeBag()

    init(viewModel: BrowserPickerViewModel) {

        super.init(frame: .zero)

        addSubview(dropdown)

        dropdown.edges(equalTo: self)

        dropdown.isBordered = false
        if viewModel.controlShowImageOnly {
            dropdown.imagePosition = .imageOnly
        }
        dropdown.setContentHuggingPriority(.required, for: .horizontal)

        let menu = NSMenu()

        for (index, option) in viewModel.options.enumerated() {
            let item = NSMenuItem()
            item.image = option.icon.with(size: .init(width: 16, height: 16))
            item.title = option.name
            item.tag = index
            menu.addItem(item)
        }

        if viewModel.options.count > 1 {
            menu.insertItem(.separator(), at: 1)
        }

        dropdown.menu = menu

        // selected index counts separators, so we have to use tags
        let browserControl = dropdown.rx.controlProperty(
            getter: { $0.selectedItem?.tag ?? 0 },
            setter: { $0.selectItem(withTag: $1) }
        )

        // hack to hide the icon
        let constraint = dropdown.width(equalTo: 15)

        viewModel.controlShowIcon
            .bind { visible in
                constraint.isActive = !visible
            }
            .disposed(by: disposeBag)

        browserControl.skip(1)
            .bind(to: viewModel.selectedIndexObserver)
            .disposed(by: disposeBag)

        viewModel.selectedIndex
            .bind(to: browserControl)
            .disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
