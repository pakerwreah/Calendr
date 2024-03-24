//
//  ContextMenu.swift
//  Calendr
//
//  Created by Paker on 18/02/23.
//

import AppKit
import RxSwift

protocol ContextMenuAction: Equatable {
    var icon: NSImage? { get }
    var title: String { get }
}

extension ContextMenuAction {
    var icon: NSImage? { nil }
}

enum ContextMenuViewModelItem<Action: ContextMenuAction>: Equatable {
    case separator
    case action(Action)
}

protocol ContextMenuViewModel<Action> {
    associatedtype Action: ContextMenuAction
    typealias ActionItem = ContextMenuViewModelItem<Action>

    var items: [ActionItem] { get }

    func triggerAction(_ action: Action)
}

class BaseContextMenuViewModel<Action: ContextMenuAction>: ContextMenuViewModel {

    typealias ActionItem = ContextMenuViewModelItem<Action>

    private(set) var items: [ActionItem] = []

    private let callback: AnyObserver<Action>

    private let disposeBag = DisposeBag()

    init(callback: AnyObserver<Action>) {
        self.callback = callback
    }

    func addSeparator() {
        if !items.isEmpty {
            items.append(.separator)
        }
    }

    func addItem(_ action: Action) {
        items.append(.action(action))
    }

    func addItems(_ actions: Action...) {
        actions.forEach(addItem)
    }

    func onAction(_ action: Action) -> Observable<Void> {
        fatalError("Not implemented")
    }

    func triggerAction(_ action: Action) {
        let callback = self.callback

        onAction(action)
            .subscribe(
                onNext: { callback.onNext(action) },
                onError: callback.onError
            )
            .disposed(by: disposeBag)
    }
}

private class ContextMenuItem<Action: ContextMenuAction>: NSMenuItem {

    private let value: Action
    private let trigger: (Action) -> Void

    init(action: Action, trigger: @escaping (Action) -> Void) {
        self.value = action
        self.trigger = trigger
        super.init(title: action.title, action: #selector(selected), keyEquivalent: "")
        self.target = self
        self.image = action.icon
    }

    @objc private func selected() {
        trigger(value)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContextMenu<ViewModel: ContextMenuViewModel>: NSMenu {

    init(viewModel: ViewModel) {

        super.init(title: "")

        for item in viewModel.items {
            switch item {
            case .separator:
                addItem(.separator())
            case .action(let action):
                addItem(ContextMenuItem(action: action, trigger: viewModel.triggerAction))
            }
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

