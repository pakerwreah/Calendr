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
                TitleInput()
                CalendarPicker()
            }

            HStack(spacing: 8) {
                DateTimeInput()
                Spacer()
                Toggle(Strings.Event.allDay, isOn: $viewModel.isAllDay)
                    .toggleStyle(.checkbox)
            }

            HStack {
                Spacer()
                Button(Strings.Reminder.Editor.save) {
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
                Strings.Reminder.Editor.Confirm.continue,
                role: .cancel,
                action: {}
            )
            Button(
                Strings.Reminder.Editor.Confirm.discard,
                role: .destructive,
                action: viewModel.confirmClose
            )
        }
        .alert(isPresented: $viewModel.isErrorVisible, error: viewModel.error) {
            Button("OK", role: .cancel, action: viewModel.dismissError)
                .keyboardShortcut(.defaultAction)
        }
    }

    @ViewBuilder
    private func TitleInput() -> some View {

        let borderOverlay = RoundedRectangle(cornerRadius: 4)
            .stroke(Color.init(nsColor: .tertiaryLabelColor))

        let textColor = Color.init(nsColor: .textColor)

        let font = Font.system(size: 13)

        TextField(Strings.Reminder.Editor.title, text: $viewModel.title)
            .focused($autoFocus)
            .font(font)
            .foregroundStyle(textColor)
            .border(.clear)
            .overlay { borderOverlay }
    }

    @ViewBuilder
    private func CalendarPicker() -> some View {
        Menu {
            Picker("", selection: $viewModel.selectedCalendarId) {
                ForEach(viewModel.calendarSections, id: \.account) { section in
                    Section(section.account.title) {
                        ForEach(section.calendars, id: \.id) { calendar in
                            Button(calendar.title, systemImage: "circle.fill") {}
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(Color(nsColor: calendar.color))
                                .tag(calendar.id)
                        }
                    }
                }
            }
            .labelsHidden()
        } label: {
            Image(systemName: "circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color(nsColor: viewModel.selectedCalendarColor))
        }
        .pickerStyle(.inline)
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    @ViewBuilder
    private func DateTimeInput() -> some View {
        DatePicker("Date", selection: $viewModel.dueDate, displayedComponents: .date)
            .datePickerStyle(.field)
            .labelsHidden()

        if !viewModel.isAllDay {
            DatePicker("Time", selection: $viewModel.dueDate, displayedComponents: .hourAndMinute)
                .datePickerStyle(.field)
                .labelsHidden()
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
