//
//  EventFullScreenViewController.swift
//  Calendr
//
//  Created by Paker on 30/05/2026.
//

import SwiftUI

typealias EventFullScreenViewController = HostingViewModelController<EventFullScreenView>

struct EventFullScreenView: ViewModelView {

    typealias ViewModel = EventFullScreenViewModel

    @State private var viewModel: ViewModel

    init (viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                Text(viewModel.title)
                    .font(.system(size: 40))
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                Text(viewModel.duration)
                    .font(.system(size: 24))
                    .fontWeight(.regular)
                    .foregroundStyle(.white)

                Spacer().frame(height: 32)

                let buttonWidth = CGFloat(200)

                VStack(spacing: 16) {
                    if let link = viewModel.link {
                        Button(action: viewModel.join) {
                            HStack {
                                Image(nsImage: link.isMeeting
                                      ? Icons.Event.video
                                      : Icons.Event.link)

                                Text(link.isMeeting
                                     ? Strings.Event.Action.join
                                     : link.url.host()
                                     ?? Strings.Event.Action.open)
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

                Spacer().frame(height: 32)
            }
            .frame(maxWidth: 1024)
            .padding(100)
        }
        .focusable()
        .focusEffectDisabled()
        .onExitCommand(perform: viewModel.performClose)
        .onAppear(perform: viewModel.onAppear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThickMaterial)
        .colorScheme(.dark)
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
