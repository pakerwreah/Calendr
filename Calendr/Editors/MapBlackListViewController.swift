//
//  MapBlackListViewController.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import SwiftUI

typealias MapBlackListViewController = HostingViewModelController<MapBlackListView>

struct MapBlackListView: ViewModelView {

    @State private var viewModel: MapBlackListViewModel

    @FocusState private var focused: MapBlackListViewModel.Item.ID?

    init (viewModel: MapBlackListViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(Strings.MapBlackList.headline)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding([.horizontal, .top])

            List($viewModel.items, selection: $viewModel.selection) { item in
                TextField("", text: item.text)
                    .focused($focused, equals: item.id)
                    .onSubmit(viewModel.save)
            }

            HStack(spacing: 12) {
                Spacer()
                Button("+") {
                    focused = viewModel.newItem()
                }
                Button("-") {
                    viewModel.removeSelected()
                }
                .disabled(!viewModel.canRemove)
            }
            .buttonStyle(.plain)
            .font(.title)
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#if DEBUG

#Preview {
    MapBlackListView(
        viewModel: MapBlackListViewModel(
            localStorage: .shared.withDefaults()
        )
    )
    .fixedSize()
}

#endif
