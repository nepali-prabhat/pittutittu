import SwiftUI

struct EditLogView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CalendarEventLogViewModel
    
    let log: CalendarEventLog
    
    @State private var title: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var tagPath: String
    
    init(log: CalendarEventLog, viewModel: CalendarEventLogViewModel) {
        self.log = log
        self.viewModel = viewModel
        
        _title = State(initialValue: log.title)
        _startDate = State(initialValue: log.startDate)
        _endDate = State(initialValue: log.endDate)
        _tagPath = State(initialValue: log.tagPath)
    }
    
    var body: some View {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    DatePicker("Start Date", selection: $startDate)
                    DatePicker("End Date", selection: $endDate)
                    TextField("Tag Path", text: $tagPath)
                }
            }
            .padding()
            .navigationTitle("Edit Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.selectedLogForEdit = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
    }
    
    private func saveChanges() {
        viewModel.editLog(
            calendarEventId: log.calendarEventId,
            title: title,
            startDate: startDate,
            endDate: endDate,
            timerEndDate: log.timerEndDate,
            tagPath: tagPath,
            tagColor: log.tagColor
        )
    }
} 