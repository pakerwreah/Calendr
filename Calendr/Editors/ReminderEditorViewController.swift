//
//  ReminderEditorViewController.swift
//  Calendr
//
//  Created by Paker on 23/10/2025.
//

import SwiftUI
import RxSwift

typealias ReminderEditorViewController = HostingViewModelController<ReminderEditorView>

struct ReminderEditorView: ViewModelView {
    @FocusState private var autoFocus: Bool
    @State private var viewModel: ReminderEditorViewModel

    init(viewModel: ReminderEditorViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: EditorMetrics.sectionSpacing) {

            EditorHeader(title: Strings.Reminder.Editor.headline) {
                CalendarPicker(
                    calendarSections: viewModel.calendarSections,
                    selectedCalendarId: $viewModel.selectedCalendarId,
                    selectedCalendarColor: viewModel.selectedCalendarColor
                )
            }

            EditorSection {
                HStack(spacing: 8) {
                    Image(systemName: "circle")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(nsColor: viewModel.selectedCalendarColor))
                        .frame(width: EditorMetrics.iconWidth)

                    TextField(Strings.Editor.title, text: $viewModel.title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .focused($autoFocus)
                }
                .padding(.horizontal, EditorMetrics.horizontalPadding)
                .frame(minHeight: 40)
            }

            EditorSection {
                EditorRow(title: Strings.Event.allDay, systemImage: "sun.max") {
                    Toggle("", isOn: $viewModel.isAllDay)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .labelsHidden()
                }
                EditorDivider()
                HStack(spacing: 8) {
                    EditorIcon(systemImage: "calendar")

                    DateTimeInput(date: $viewModel.dueDate, showTime: !viewModel.isAllDay)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, EditorMetrics.horizontalPadding)
                .frame(minHeight: EditorMetrics.rowHeight)
            }

            EditorSection {
                EditorNotesRow(placeholder: Strings.Event.Editor.notes, text: $viewModel.notes)
            }

            EditorFooter(isSaveEnabled: viewModel.hasValidInput, onSave: viewModel.saveReminder)
                .padding(.top, 4)
        }
        .padding(EditorMetrics.padding)
        .frame(width: 380)
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
            dueDate: .now,
            calendarService: MockCalendarServiceProvider(
                calendars: [
                    .make(id: "1", account: "iCloud", title: "Reminders", color: .systemBlue),
                    .make(id: "2", account: "iCloud", title: "Groceries", color: .systemRed),
                    .make(id: "3", account: "Google", title: "Todos", color: .systemYellow),
                ]
            ),
            scheduler: MainScheduler.instance
        )
    )
}

#endif
