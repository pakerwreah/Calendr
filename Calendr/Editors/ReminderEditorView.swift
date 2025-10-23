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
            Text("New Reminder")
                .font(.title2)
                .bold()

            let borderOverlay = RoundedRectangle(cornerRadius: 4)
                .stroke(Color.init(nsColor: .tertiaryLabelColor))

            let textColor = Color.init(nsColor: .textColor)

            let font = Font.system(size: 13)

            TextField("Title", text: $viewModel.title)
                .focused($autoFocus)
                .font(font)
                .foregroundStyle(textColor)
                .border(.clear)
                .overlay { borderOverlay }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.notes)
                    .font(font)
                    .foregroundStyle(textColor)
                    .frame(height: 60)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                    .overlay { borderOverlay }

                if viewModel.notes.trimmed.isEmpty {
                    Text("Notes")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .foregroundStyle(.secondary)
                }
            }

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
                Button("Save") {
                    viewModel.saveReminder()
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(!viewModel.hasValidInput)
            }
        }
        .padding(20)
        .frame(width: 300)
        .fixedSize()
        .onAppear {
            autoFocus = true
        }
        .confirmationDialog("", isPresented: $viewModel.isCloseConfirmationVisible) {
            Button("Continue editing", role: .cancel, action: {})
            Button("Discard all changes", role: .destructive, action: viewModel.confirmClose)
        }
    }
}

// MARK: - Preview

#Preview {
    ReminderEditorView(viewModel: .init())
}
