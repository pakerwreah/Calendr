//
//  ReminderEditorViewModel.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import RxSwift

class ReminderEditorViewModel: ObservableObject, HostingControllerDelegate {
    @Published var title = ""
    @Published var dueDate: Date
    @Published var isCloseConfirmationVisible = false
    @Published var isErrorVisible = false

    private(set) var error: UnexpectedError? {
        didSet {
            if error != nil {
                isErrorVisible = true
            }
        }
    }

    private let calendarService: CalendarServiceProviding

    private let disposeBag = DisposeBag()

    init(dueDate: DueDate, calendarService: CalendarServiceProviding) {
        self.dueDate = dueDate.date
        self.calendarService = calendarService
    }

    var onCloseConfirmed: () -> Void = {
        print("Close editor modal")
    }

    func confirmClose() {
        isCloseConfirmationVisible = false
        onCloseConfirmed()
    }

    func dismissError() {
        isErrorVisible = false
        error = nil
    }

    var hasValidInput: Bool {
        !title.trimmed.isEmpty
    }

    func saveReminder() {
        guard hasValidInput else { return }

        calendarService.createReminder(title: title, date: dueDate)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                self?.confirmClose()
            }, onError: { [weak self] error in
                self?.error = error.unexpected
            })
            .disposed(by: disposeBag)
    }

    func requestWindowClose() -> Bool {
        if hasValidInput {
            isCloseConfirmationVisible = true
        }
        return !isCloseConfirmationVisible
    }
}
