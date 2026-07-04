//
//  MapBlackListViewController.swift
//  Calendr
//
//  Created by Paker on 28/10/2025.
//

import SwiftUI
import RxSwift

typealias MapBlackListViewController = HostingViewModelController<MapBlackListView>

struct MapBlackListView: ViewModelView {

    typealias ViewModel = MapBlackListViewModel

    @State private var viewModel: ViewModel

    @FocusState private var focused: ViewModel.Item.ID?

    init (viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Strings.MapBlackList.headline)
                .foregroundStyle(.secondary)
                .padding([.horizontal, .top])

            ScrollViewReader { proxy in
                List($viewModel.items, selection: $viewModel.selection) { item in
                    TextField("", text: item.text)
                        .focused($focused, equals: item.id)
                        .onSubmit(viewModel.save)
                }
                .onChange(of: viewModel.items.count) { before, after in
                    if after > before, let id = viewModel.items.last?.id {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
            .safeAreaPadding(.bottom, 32)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(.windowBackgroundColor).opacity(0.0),
                        Color(.windowBackgroundColor).opacity(1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 48)
                .allowsHitTesting(false)
            }

            HStack {
                HStack(spacing: 4) {
                    Button(" + ") {
                        focused = viewModel.newItem()
                    }
                    Button(" - ") {
                        viewModel.removeSelected()
                    }
                    .disabled(!viewModel.canRemove)
                }
                .font(.title)
                .buttonStyle(.plain)

                Spacer()

                if !viewModel.isRegexVisible {
                    Button("Regex") {
                        viewModel.isRegexVisible.toggle()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            .focusEffectDisabled()
            .padding(.horizontal)
            .padding(.bottom, 12)

            if viewModel.isRegexVisible {
                HStack {
                    Text("Regex:")
                        .foregroundStyle(.secondary)

                    TextInput(
                        placeholder: "",
                        text: $viewModel.regexText,
                        isInvalid: viewModel.isRegexInvalid
                    )
                    .onSubmit(viewModel.save)
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

#if DEBUG

#Preview {
    let localStorage = {
        let storage = MockLocalStorageProvider()
        storage.showMapBlacklistItems = [
            "Microsoft Teams",
            "Google Meet",
            "Discord",
            "Slack",
            "Zoom",
            "Skype",
            "WhatsApp",
            "Telegram",
            "WeChat",
            "Facebook",
        ]
        return storage
    }()

    MapBlackListView(
        viewModel: MapBlackListViewModel(
            localStorage: localStorage,
            scheduler: MainScheduler.instance
        )
    )
    .fixedSize()
}

#endif
