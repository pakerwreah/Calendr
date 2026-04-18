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

            let borderOverlay = RoundedRectangle(cornerRadius: 4)
                .stroke(Color.init(nsColor: .tertiaryLabelColor))

            let textColor = Color.init(nsColor: .textColor)

            let font = Font.system(size: 13)

            HStack(spacing: 8) {
                TextField(Strings.Reminder.Editor.title, text: $viewModel.title)
                    .focused($autoFocus)
                    .font(font)
                    .foregroundStyle(textColor)
                    .border(.clear)
                    .overlay { borderOverlay }

                calendarDropdown
            }

            HStack(spacing: 8) {
                DatePicker("Date", selection: $viewModel.dueDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .labelsHidden()

                if !viewModel.isAllDay {
                    DatePicker("Time", selection: $viewModel.dueDate, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.field)
                        .labelsHidden()
                }

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
    private var calendarDropdown: some View {
        Menu {
            ForEach(viewModel.calendarSections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.calendars, id: \.id) { calendar in
                        Button {
                            viewModel.selectedCalendarId = calendar.id
                        } label: {
                            Label {
                                Text(calendar.title)
                            } icon: {
                                Image(nsImage: .colorCircle(calendar.color))
                            }
                        }
                    }
                }
            }
        } label: {
            Circle()
                .fill(Color(nsColor: viewModel.selectedCalendarColor))
                .frame(width: 12, height: 12)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Preview

#if DEBUG

#Preview {
    ReminderEditorView(
        viewModel: .init(
            dueDate: .init(date: .now),
            calendarService: MockCalendarServiceProvider()
        )
    )
}

#endif
