//
//  AboutViewController.swift
//  Calendr
//
//  Created by Paker on 18/02/2021.
//

import Cocoa
import UserNotifications

class AboutViewController: NSViewController, UNUserNotificationCenterDelegate {

    private let quitButton: NSButton
    private let linkView: NSTextView
    private let newVersionButton: NSButton
    private let appVersion = "v\(BuildConfig.appVersion)"

    init() {
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
        newVersionButton.action = #selector(openReleasePage)
        newVersionButton.refusesFirstResponder = true
        newVersionButton.bezelStyle = .roundRect

        setUpAccessibility()
        setUpReleaseCheck()
    }

    override func loadView() {

        if let version = UserDefaults.standard.string(forKey: Prefs.lastCheckedVersion), version != appVersion {
            showNewVersionButton(Strings.newVersion(version))
        } else {
            newVersionButton.isHidden = true
        }

        view = NSStackView(views: [
            Label(text: "Calendr", font: .systemFont(ofSize: 16, weight: .semibold), align: .center),
            .spacer(height: 0),
            Label(text: appVersion, font: .systemFont(ofSize: 13), align: .center),
            Label(text: "\(BuildConfig.date) - \(BuildConfig.time)", color: .secondaryLabelColor, align: .center),
            .spacer(height: 4),
            Label(text: #"¯\_(ツ)_/¯"#, font: .systemFont(ofSize: 16), align: .center),
            .spacer(height: 4),
            Label(text: "© 2020 - \(BuildConfig.date.suffix(4)) Carlos Enumo", align: .center),
            linkView,
            newVersionButton,
            .spacer(height: 4),
            quitButton
        ])
        .with(insets: .init(bottom: 1))
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

    private func setUpReleaseCheck() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            guard granted else { return }
            self.checkRelease()
            DispatchQueue.main.async {
                Timer.scheduledTimer(
                    withTimeInterval: 60 * 60,
                    repeats: true
                ) { _ in
                    DispatchQueue.global().async {
                        self.checkRelease()
                    }
                }
            }
        }
    }

    private func showNewVersionButton(_ title: String) {
        newVersionButton.title = title
        newVersionButton.isHidden = false
    }

    private func checkRelease() {
        do {
            let url = "https://api.github.com/repos/pakerwreah/Calendr/releases/latest"
            let data = try Data(contentsOf: URL(string: url)!)
            guard
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let version = json["name"] as? String
            else { return }

            guard version != appVersion else {
                DispatchQueue.main.async {
                    self.newVersionButton.isHidden = true
                }
                UserDefaults.standard.set(version, forKey: Prefs.lastCheckedVersion)
                return
            }

            guard version != UserDefaults.standard.string(forKey: Prefs.lastCheckedVersion) else { return }

            let message = Strings.newVersion(version)

            DispatchQueue.main.async {
                self.showNewVersionButton(message)
            }

            let content = UNMutableNotificationContent()
            content.title = message
            content.sound = .default

            UNUserNotificationCenter.current().add(
                UNNotificationRequest(
                    identifier: UUID().uuidString,
                    content: content,
                    trigger: nil
                )
            ) { error in
                if let error {
                    print(error.localizedDescription)
                    return
                }
                UserDefaults.standard.set(version, forKey: Prefs.lastCheckedVersion)
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    @objc private func openReleasePage() {
        NSWorkspace.shared.open(URL(string: "https://github.com/pakerwreah/Calendr/releases/latest")!)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        openReleasePage()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
