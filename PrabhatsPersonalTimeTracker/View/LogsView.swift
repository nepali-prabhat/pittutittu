import SwiftUI

struct LogsView: View {
    @StateObject private var viewModel = CalendarEventLogViewModel.shared
    @State private var selectedLogIds: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    @State private var selectedLogForEdit: CalendarEventLog?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                LogsTableView(
                    selectedLogIds: $selectedLogIds,
                    onEdit: { log in
                        selectedLogForEdit = log
                    }
                )
            }
            .navigationTitle("Time Logs")
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Selected", systemImage: "trash")
                    }
                    .disabled(selectedLogIds.isEmpty)
                }
                
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button(action: {
                            // TODO: Implement export functionality
                        }) {
                            Label("Export Logs", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            // TODO: Implement import functionality
                        }) {
                            Label("Import Logs", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Label("Import/Export", systemImage: "ellipsis.circle")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button(action: {
                            // TODO: Implement filter by date range
                        }) {
                            Label("Filter by Date", systemImage: "calendar")
                        }
                        
                        Button(action: {
                            // TODO: Implement filter by tag
                        }) {
                            Label("Filter by Tag", systemImage: "tag")
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .alert("Delete Selected Logs", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    for log in viewModel.logs where selectedLogIds.contains(log.id) {
                        viewModel.deleteLog(calendarEventId: log.calendarEventId)
                    }
                    selectedLogIds.removeAll()
                }
            } message: {
                Text("Are you sure you want to delete \(selectedLogIds.count) selected log(s)? This action cannot be undone.")
            }
            .sheet(item: $selectedLogForEdit) { log in
                EditLogView(log: log, viewModel: viewModel)
            }
        }
    }
}

struct LogsTableView: View {
    @ObservedObject private var viewModel = CalendarEventLogViewModel.shared
    @Binding var selectedLogIds: Set<UUID>
    let onEdit: (CalendarEventLog) -> Void
    
    var body: some View {
        Table(viewModel.logs) {
            TableColumn("") { log in
                HStack(spacing: 4) {
                    Toggle("", isOn: Binding(
                        get: { selectedLogIds.contains(log.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedLogIds.insert(log.id)
                            } else {
                                selectedLogIds.remove(log.id)
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                    
                    Menu {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(log.calendarEventId, forType: .string)
                        }) {
                            Label("Copy Event ID", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: {
                            onEdit(log)
                        }) {
                            Label("Edit Event", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                }
                .frame(width: 60)
            }
            .width(60)
            
            TableColumn("Title", value: \.title)
            TableColumn("Start Time") { log in
                Text(log.startDate.formatted(date: .abbreviated, time: .shortened))
            }
            TableColumn("Expected End Time") { log in
                Text(log.endDate.formatted(date: .abbreviated, time: .shortened))
            }
            TableColumn("Timer End") { log in
                if let timerEndDate = log.timerEndDate {
                    Text(timerEndDate.formatted(date: .abbreviated, time: .shortened))
                } else {
                    Text("-")
                }
            }
            TableColumn("Duration") { log in
                HStack {
                    Text(formatDuration(from: log.startDate, to: log.timerEndDate ?? log.endDate))
                    if log.timerEndDate == nil {
                        Text("(expected)")
                    }
                }
            }
            TableColumn("Tag Path", value: \.tagPath)
            TableColumn("Tag Color") { log in
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: log.tagColor) ?? .gray)
                        .frame(width: 12, height: 12)
                }
            }
            TableColumn("EventId") { log in
                Text(log.calendarEventId)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(alignment: .topLeading) {
            if !viewModel.logs.isEmpty {
                    Toggle("", isOn: Binding(
                        get: { selectedLogIds.count == viewModel.logs.count },
                        set: { isSelected in
                            if isSelected {
                                selectedLogIds = Set(viewModel.logs.map { $0.id })
                            } else {
                                selectedLogIds.removeAll()
                            }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()
                .padding(.leading, 16)
                .padding(.top, 8)
            }
        }
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    LogsView()
} 
