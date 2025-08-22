//
//  EventViewController.swift
//  CalendrEditor
//
//  Created by Paker on 21/08/2025.
//

import EventKitUI

class EventViewController: EKEventEditViewController, EKEventEditViewDelegate {

    private let eventId: String?

    init(eventId: String? = nil) {

        self.eventId = eventId

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        eventStore = EKEventStore()

        editViewDelegate = self

        eventStore.requestFullAccessToEvents() { [weak self] granted, error in
            guard let self else {
                return
            }
            if let error {
                print(error.localizedDescription)
            }
            print("Granted: \(granted)")

            if let eventId, let event = eventStore.event(withIdentifier: eventId) {
                self.event = event
            }
        }
    }

    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {

        switch action {
            case .canceled:
                print("canceled")
            case .saved:
                print("saved")
            case .deleted:
                print("deleted")
            @unknown default:
                fatalError()
        }

        exit(0)
    }
}
