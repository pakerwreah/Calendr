//
//  PreviewExtensions.swift
//  Calendr
//
//  Created by Paker on 04/07/2021.
//

#if DEBUG

import SwiftUI

private extension NSAppearance {

    static func from(_ colorScheme: ColorScheme) -> Self {
        .init(named: colorScheme == .dark ? .vibrantDark : .vibrantLight)!
    }
}

extension NSViewRepresentable {

    func updateNSView(_ nsView: NSViewType, context: Context) {
        NSApp.appearance = .from(context.environment.colorScheme)
    }
}

private struct ViewWrapper: NSViewRepresentable {

    let view: NSView

    func makeNSView(context: Context) -> some NSView { view }
}

extension NSView {

    func preview() -> some NSViewRepresentable { ViewWrapper(view: self) }
}

#endif
