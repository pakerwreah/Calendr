//
//  EventEditorViewController.swift
//  Calendr
//
//  Created by Paker on 14/06/2026.
//

import SwiftUI
import RxSwift

typealias EventEditorViewController = HostingViewModelController<EventEditorView>

struct EventEditorView: ViewModelView {
    @FocusState private var autoFocus: Bool
    @State private var viewModel: EventEditorViewModel

    init(viewModel: EventEditorViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 16) {

            Text(Strings.Event.Editor.headline)
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

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    Text(Strings.Event.allDay + ":")
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.trailing)

                    Toggle(isOn: $viewModel.isAllDay) { }
                        .toggleStyle(.checkbox)
                        .gridColumnAlignment(.leading)
                }
                GridRow {
                    Text(Strings.Event.Editor.start + ":")
                        .foregroundStyle(.secondary)

                    DateTimeInput(
                        date: $viewModel.startDate,
                        showTime: !viewModel.isAllDay,
                        timeZone: viewModel.selectedTimeZone,
                        isInvalid: !viewModel.hasValidDateRange
                    )
                }
                GridRow {
                    Text(Strings.Event.Editor.end + ":")
                        .foregroundStyle(.secondary)

                    DateTimeInput(
                        date: $viewModel.endDate,
                        showTime: !viewModel.isAllDay,
                        timeZone: viewModel.selectedTimeZone,
                        isInvalid: !viewModel.hasValidDateRange
                    )
                }
                GridRow {
                    Text(Strings.Event.Editor.timeZone + ":")
                        .foregroundStyle(.secondary)

                    TimeZonePicker(selectedIdentifier: $viewModel.selectedTimeZoneIdentifier)
                }
                GridRow {
                    Text(Strings.Event.Editor.alert + ":")
                        .foregroundStyle(.secondary)

                    Picker("", selection: $viewModel.selectedAlert) {
                        ForEach(EventAlert.allCases, id: \.self) { alert in
                            Text(alert.title).tag(alert)
                        }
                    }
                    .labelsHidden()
                }
            }

            TextInput(placeholder: Strings.Event.Editor.location, text: $viewModel.location)

            TextInput(placeholder: Strings.Event.Editor.url, text: $viewModel.url)

            TextArea(placeholder: Strings.Event.Editor.notes, text: $viewModel.notes)
                .frame(height: 60)

            HStack {
                Spacer()
                Button(Strings.Editor.save) {
                    viewModel.saveEvent()
                }
                .disabled(!viewModel.hasValidInput)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
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
    EventEditorView(
        viewModel: .init(
            startDate: .init(date: .now),
            dateProvider: MockDateProvider(calendar: .current),
            calendarService: MockCalendarServiceProvider(
                calendars: [
                    .make(id: "1", account: "iCloud", title: "Work", color: .systemBlue),
                    .make(id: "2", account: "iCloud", title: "Personal", color: .systemRed),
                ]
            ),
            scheduler: MainScheduler.instance
        )
    )
}

#endif
