//
//  AboutViewController.swift
//  Calendr
//
//  Created by Paker on 18/02/2021.
//

import Cocoa
import RxSwift

class AboutViewController: NSViewController {

    private let quitButton: NSButton
    private let linkView: NSTextView
    private let newVersionButton: NSButton
    private let autoUpdater: AutoUpdater

    private let disposeBag = DisposeBag()

    init(autoUpdater: AutoUpdater) {
        self.autoUpdater = autoUpdater

        quitButton = NSButton(title: Strings.quit, target: NSApp, action: #selector(NSApp.terminate))
        quitButton.refusesFirstResponder = true

        linkView = NSTextView()
        linkView.string = "https://github.com/pakerwreah"
        linkView.backgroundColor = .clear
        linkView.linkTextAttributes?[.underlineColor] = NSColor.clear
        linkView.isAutomaticLinkDetectionEnabled = true
        linkView.checkTextInDocument(nil)
        linkView.isEditable = false
        linkView.alignment = .center
        linkView.height(equalTo: 15)

        newVersionButton = NSButton()

        super.init(nibName: nil, bundle: nil)

        newVersionButton.target = self
        newVersionButton.title = Strings.AutoUpdate.checkForUpdates
        newVersionButton.action = #selector(checkForUpdates)
        newVersionButton.refusesFirstResponder = true
        newVersionButton.bezelStyle = .roundRect

        setUpAccessibility()
        setUpBindings()
    }

    override func loadView() {

        view = NSStackView(views: [
            Label(text: "Calendr", font: .systemFont(ofSize: 16, weight: .semibold), align: .center),
            .spacer(height: 0),
            Label(text: BuildConfig.appVersion, font: .systemFont(ofSize: 13), align: .center),
            Label(text: "\(BuildConfig.date) - \(BuildConfig.time)", color: .secondaryLabelColor, align: .center),
            .spacer(height: 4),
            Label(text: #"¯\_(ツ)_/¯"#, font: .systemFont(ofSize: 16), align: .center),
            .spacer(height: 4),
            Label(text: "© 2020 - \(BuildConfig.date.suffix(4)) Carlos Enumo", align: .center),
            linkView,
            .spacer(height: 2),
            newVersionButton,
            .spacer(height: 8),
            quitButton
        ])
        .with(insets: .init(bottom: 8))
        .with(orientation: .vertical)
    }

    private func setUpAccessibility() {

        guard BuildConfig.isUITesting else { return }

        view.setAccessibilityElement(true)
        view.setAccessibilityIdentifier(Accessibility.Settings.About.view)

        quitButton.setAccessibilityElement(true)
        quitButton.setAccessibilityRole(.button)
        quitButton.setAccessibilityIdentifier(Accessibility.Settings.About.quitBtn)
    }

    private func setUpBindings() {

        autoUpdater.newVersionAvailable.bind { [weak self] status in
            guard let self else { return }
            switch status {
            case .initial:
                newVersionButton.title = Strings.AutoUpdate.checkForUpdates
                newVersionButton.action = #selector(checkForUpdates)
                newVersionButton.isEnabled = true

            case .fetching:
                newVersionButton.isEnabled = false
                newVersionButton.title = Strings.AutoUpdate.fetchingReleases

            case .downloading(let version):
                newVersionButton.isEnabled = false
                newVersionButton.title = Strings.AutoUpdate.downloading(version)

            case .newVersion(let version):
                newVersionButton.title = Strings.AutoUpdate.newVersion(version)
                newVersionButton.action = #selector(installUpdates)
                newVersionButton.isEnabled = true
            }
        }
        .disposed(by: disposeBag)
    }

    @objc private func checkForUpdates() {
        autoUpdater.checkRelease(notify: false)
    }

    @objc private func installUpdates() {
        autoUpdater.downloadAndInstall()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
