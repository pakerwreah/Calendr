//
//  ReminderEditorViewModel.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

class ReminderEditorViewModel: ObservableObject, HostingControllerDelegate {
    @Published var title = ""
    @Published var notes = ""
    @Published var dueDate = Date()
    @Published var isCloseConfirmationVisible = false

    var onCloseConfirmation: () -> Void = {
        print("Close editor modal")
    }

    func confirmClose() {
        isCloseConfirmationVisible = false
        onCloseConfirmation()
    }

    var hasValidInput: Bool {
        !title.trimmed.isEmpty
    }

    func saveReminder() {
        guard hasValidInput else { return }

        // TODO: implement saving
        print("✅ Saved reminder: \(title), due: \(dueDate)")
    }

    func requestWindowClose() -> Bool {
        if [title, notes].allSatisfy(\.trimmed.isEmpty) {
            return true
        }
        isCloseConfirmationVisible = true
        return false
    }
}
