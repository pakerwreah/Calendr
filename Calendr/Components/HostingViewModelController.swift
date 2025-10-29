//
//  HostingViewModelController.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import SwiftUI

protocol ViewModelRepresentable {

    associatedtype ViewModel

    init(viewModel: ViewModel)
}

protocol ViewModelView: View, ViewModelRepresentable {}

class HostingViewModelController<RootView: ViewModelView>: HostingWindowController<RootView> {

    init(viewModel: RootView.ViewModel) {
        super.init(rootView: RootView(viewModel: viewModel))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
