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
    @State private var autoFocus: Bool = false
    @State private var viewModel: EventEditorViewModel

    init(viewModel: EventEditorViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: EditorMetrics.sectionSpacing) {

            EditorHeader(title: Strings.Event.Editor.headline) {
                CalendarPicker(
                    calendarSections: viewModel.calendarSections,
                    selectedCalendarId: $viewModel.selectedCalendarId,
                    selectedCalendarColor: viewModel.selectedCalendarColor
                )
            }

            EditorSection {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(nsColor: viewModel.selectedCalendarColor))
                        .frame(width: 4, height: 20)
                        .frame(width: EditorMetrics.iconWidth)

                    HighlightedTextInput(
                        text: $viewModel.title,
                        focus: $autoFocus,
                        placeholder: Strings.Editor.title,
                        highlights: viewModel.titleHighlights,
                        fontSize: 15,
                        showsBorder: false
                    )
                    .frame(maxWidth: .infinity)
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
                EditorRow(title: Strings.Event.Editor.start, systemImage: "clock") {
                    DateTimeInput(
                        date: $viewModel.startDate,
                        showTime: !viewModel.isAllDay,
                        timeZone: viewModel.selectedTimeZone,
                        isInvalid: !viewModel.hasValidDateRange
                    )
                }
                EditorDivider()
                EditorRow(title: Strings.Event.Editor.end, systemImage: "clock.badge.checkmark") {
                    DateTimeInput(
                        date: $viewModel.endDate,
                        showTime: !viewModel.isAllDay,
                        timeZone: viewModel.selectedTimeZone,
                        isInvalid: !viewModel.hasValidDateRange
                    )
                }
                EditorDivider()
                EditorRow(title: Strings.Event.Editor.timeZone, systemImage: "globe") {
                    TimeZonePicker(selectedIdentifier: $viewModel.selectedTimeZoneIdentifier)
                        .frame(maxWidth: 220)
                }
            }

            EditorSection {
                EditorRow(title: Strings.Event.Editor.alert, systemImage: "bell") {
                    Picker("", selection: $viewModel.selectedAlert) {
                        ForEach(EventAlert.allCases, id: \.self) { alert in
                            Text(alert.title).tag(alert)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                }
            }

            EditorSection {
                EditorTextFieldRow(
                    placeholder: Strings.Event.Editor.location,
                    systemImage: "mappin.and.ellipse",
                    text: $viewModel.location
                )
                EditorDivider()
                EditorTextFieldRow(
                    placeholder: Strings.Event.Editor.url,
                    systemImage: "link",
                    text: $viewModel.url
                )
                EditorDivider()
                EditorNotesRow(placeholder: Strings.Event.Editor.notes, text: $viewModel.notes)
            }

            EditorFooter(isSaveEnabled: viewModel.hasValidInput, onSave: viewModel.saveEvent)
                .padding(.top, 4)
        }
        .padding(EditorMetrics.padding)
        .frame(width: 480)
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
            startDate: .now,
            dateProvider: MockDateProvider(calendar: .current),
            calendarService: MockCalendarServiceProvider(
                calendars: [
                    .make(id: "1", account: "iCloud", title: "Work", color: .systemBlue),
                    .make(id: "2", account: "iCloud", title: "Personal", color: .systemRed),
                ]
            ),
            settings: MockEventEditorSettings(),
            scheduler: MainScheduler.instance
        )
    )
}

#endif
