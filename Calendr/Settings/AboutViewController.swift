//
//  AboutViewController.swift
//  Calendr
//
//  Created by Paker on 18/02/2021.
//

import Cocoa

class AboutViewController: NSViewController {

    override func loadView() {

        let link = NSTextView()
        link.string = "https://github.com/pakerwreah"
        link.linkTextAttributes?[.underlineColor] = NSColor.clear
        link.isAutomaticLinkDetectionEnabled = true
        link.checkTextInDocument(nil)
        link.isEditable = false
        link.alignment = .center
        link.height(equalTo: 15)

        view = NSStackView(views: [
            Label(text: "Calendr", font: .systemFont(ofSize: 16, weight: .semibold), align: .center),
            .spacer(height: 0),
            Label(text: "v\(BuildConfig.appVersion)", font: .systemFont(ofSize: 13), align: .center),
            Label(text: "\(BuildConfig.date) - \(BuildConfig.time)", color: .secondaryLabelColor, align: .center),
            .spacer(height: 4),
            Label(text: #"¯\_(ツ)_/¯"#, font: .systemFont(ofSize: 16), align: .center),
            .spacer(height: 4),
            Label(text: "© 2020 - \(BuildConfig.date.suffix(4)) Carlos Enumo", align: .center),
            link,
            .spacer(height: 4),
            NSButton(title: Strings.quit, target: NSApp, action: #selector(NSApp.terminate))
        ])
        .with(orientation: .vertical)
    }
}
