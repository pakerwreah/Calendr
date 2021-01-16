//
//  SettingsViewController.swift
//  Calendr
//
//  Created by Paker on 14/01/21.
//

import Cocoa

class SettingsViewController: NSViewController {

    private let settingsViewModel: SettingsViewModel

    private let calendarsView: CalendarPickerView

    init(settingsViewModel: SettingsViewModel, calendarsViewModel: CalendarPickerViewModel) {

        self.settingsViewModel = settingsViewModel
        self.calendarsView = CalendarPickerView(viewModel: calendarsViewModel)

        super.init(nibName: nil, bundle: nil)

        title = "Settings"
    }

    override func loadView() {
        view = NSView()

        view.addSubview(calendarsView)

        calendarsView.edges(to: view, constant: 16)
    }

    override func viewDidAppear() {
        view.window?.styleMask.remove(.resizable)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
