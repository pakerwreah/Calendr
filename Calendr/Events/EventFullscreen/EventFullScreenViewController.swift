//
//  EventFullScreenViewController.swift
//  Calendr
//
//  Created by Paker on 30/05/2026.
//

import SwiftUI
import RxSwift

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

            SliderPopupButton(value: $viewModel.transparencyLevel)
                .controlSize(.large)
                .imageScale(.large)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(32)

        }
        .focusable()
        .focusEffectDisabled()
        .onExitCommand(perform: viewModel.performClose)
        .onAppear(perform: viewModel.onAppear)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(viewModel.material.value)
        .colorScheme(.dark)
    }
}

#if DEBUG

#Preview(traits: .fixedLayout(width: 800, height: 600)) {
    ZStack {
        DesktopWallpaper()
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
                localStorage: MockLocalStorageProvider().withDefaults(),
                workspace: MockWorkspaceServiceProvider(),
                scheduler: MainScheduler.instance,
                onSkip: { }
            )
        )
    }
}

#endif

private struct SliderPopupButton: View {

    @Binding var value: Int
    @State private var isPopupPresented: Bool = false

    var body: some View {
        Button {
            isPopupPresented.toggle()
        } label: {
            Image(systemName: "gear")
        }
        .buttonBorderShape(.circle)
        .popover(isPresented: $isPopupPresented, arrowEdge: .trailing) {
            SliderPopupView(value: $value)
        }
    }
}

private struct SliderPopupView: View {
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Strings.Settings.Appearance.transparency)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                Image(nsImage: Icons.Settings.transparencyLow)

                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: 0...4, step: 1)

                Image(nsImage: Icons.Settings.transparencyHigh)
            }
            .frame(width: 200)
        }
        .padding()
    }
}

private struct DesktopWallpaper: View {
    let imageURL = NSWorkspace.shared.desktopImageURL(for: .main!)

    var body: some View {
        GeometryReader { geometry in
            AsyncImage(url: imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.secondary.opacity(0.2)
            }
            // Match the container's calculated dimensions exactly
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
    }
}
