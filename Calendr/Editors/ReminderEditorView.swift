//
//  ReminderEditorView.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import SwiftUI

struct ReminderEditorView: View {
    @FocusState private var autoFocus: Bool
    @StateObject private var viewModel: ReminderEditorViewModel

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

            TextField(Strings.Reminder.Editor.title, text: $viewModel.title)
                .focused($autoFocus)
                .font(font)
                .foregroundStyle(textColor)
                .border(.clear)
                .overlay { borderOverlay }

            HStack(spacing: 8) {
                DatePicker("Date", selection: $viewModel.dueDate, displayedComponents: .date)
                    .datePickerStyle(.field)
                    .labelsHidden()

                DatePicker("Time", selection: $viewModel.dueDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.field)
                    .labelsHidden()
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
