//
//  ReminderEditorViewController.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import SwiftUI

typealias ReminderEditorViewController = HostingViewModelController<ReminderEditorView>

struct ReminderEditorView: ViewModelView {
    @FocusState private var autoFocus: Bool
    @State private var viewModel: ReminderEditorViewModel

    init(viewModel: ReminderEditorViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text(Strings.Reminder.Editor.headline)
                .font(.title2)
                .bold()

            HStack(spacing: 8) {
                TextInput(
                    placeholder: Strings.Editor.title,
                    text: $viewModel.title,
                    focus: $autoFocus
                )
                CalendarPicker(
                    calendarSections: viewModel.calendarSections,
                    selectedCalendarId: $viewModel.selectedCalendarId,
                    selectedCalendarColor: viewModel.selectedCalendarColor
                )
            }

            HStack(spacing: 8) {
                DateTimeInput(date: $viewModel.dueDate, showTime: !viewModel.isAllDay)
                Spacer()
                Toggle(Strings.Event.allDay, isOn: $viewModel.isAllDay)
                    .toggleStyle(.checkbox)
            }

            HStack {
                Spacer()
                Button(Strings.Editor.save) {
                    viewModel.saveReminder()
                }
                .disabled(!viewModel.hasValidInput)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 300)
        .fixedSize()
        .onAppear {
            autoFocus = true
        }
        .confirmationDialog("", isPresented: $viewModel.isCloseConfirmationVisible) {
            Button(
                Strings.Editor.Confirm.continue,
                role: .cancel,
                action: {}
            )
            Button(
                Strings.Editor.Confirm.discard,
                role: .destructive,
                action: viewModel.confirmClose
            )
        }
        .alert(isPresented: $viewModel.isErrorVisible, error: viewModel.error) {
            Button("OK", role: .cancel, action: viewModel.dismissError)
                .keyboardShortcut(.defaultAction)
        }
    }
}

// MARK: - Preview

#if DEBUG

#Preview {
    ReminderEditorView(
        viewModel: .init(
            dueDate: .init(date: .now),
            calendarService: MockCalendarServiceProvider(
                calendars: [
                    .make(id: "1", account: "iCloud", title: "Reminders", color: .systemBlue),
                    .make(id: "2", account: "iCloud", title: "Groceries", color: .systemRed),
                    .make(id: "3", account: "Google", title: "Todos", color: .systemYellow),
                ]
            )
        )
    )
}

#endif
