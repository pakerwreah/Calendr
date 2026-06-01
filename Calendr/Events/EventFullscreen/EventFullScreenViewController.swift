//
//  EventFullScreenViewController.swift
//  Calendr
//
//  Created by Paker on 30/05/2026.
//

import SwiftUI

typealias EventFullScreenViewController = HostingViewModelController<EventFullScreenView>

struct EventFullScreenView: ViewModelView {

    @Environment(\.colorScheme) var colorScheme

    typealias ViewModel = EventFullScreenViewModel

    @State private var viewModel: ViewModel

    init (viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        let bgColor = colorScheme == .dark ? Color.black : Color.white
        let shadowRadius = CGFloat(5)
        ZStack {
            VStack(spacing: 16) {
                Text(viewModel.title)
                    .font(.system(size: 40))
                    .fontWeight(.medium)
                    .shadow(color: bgColor, radius: shadowRadius)

                Text(viewModel.duration)
                    .font(.system(size: 24))
                    .fontWeight(.regular)
                    .shadow(color: bgColor, radius: shadowRadius)

                Spacer(minLength: 100)

                let buttonWidth = CGFloat(200)

                VStack(spacing: 16) {
                    if viewModel.link?.isMeeting == true {
                        Button(action: viewModel.join) {
                            HStack {
                                Image(nsImage: Icons.Event.video)
                                Text(Strings.Event.Action.join)
                            }
                            .frame(width: buttonWidth)
                        }
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button(action: viewModel.performClose) {
                            Text("OK")
                                .frame(width: buttonWidth)
                        }
                        .keyboardShortcut(.defaultAction)
                    }
                    Button(action: viewModel.skip) {
                        HStack {
                            Image(nsImage: Icons.Event.skip)
                            Text(Strings.Event.Action.skip)
                        }
                        .frame(width: buttonWidth)
                    }
                }
                .disabled(viewModel.isDismissLocked)
                .controlSize(.extraLarge)

                Spacer(minLength: 100)
            }
            .padding(32)
            .fixedSize()
        }
        .focusable()
        .focusEffectDisabled()
        .onExitCommand(perform: viewModel.performClose)
        .onAppear(perform: viewModel.onAppear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.01))
    }
}

#if DEBUG

#Preview {
    EventFullScreenView(
        viewModel: EventFullScreenViewModel(
            event: .make(
                start: .make(year: 2026, month: 5, day: 30, hour: 21, minute: 0),
                end: .make(year: 2026, month: 5, day: 30, hour: 21, minute: 30),
                title: "Design Review",
                url: URL(string: "https://meet.google.com")
            ),
            dateProvider: MockDateProvider(),
            forceLocalTimeZone: false,
            workspace: MockWorkspaceServiceProvider(),
            onSkip: { }
        )
    )
}

#endif
