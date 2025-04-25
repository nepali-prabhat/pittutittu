import SwiftUI

struct LogsView: View {
    @StateObject private var viewModel = CalendarEventLogViewModel.shared
    @State private var selectedLogIds: Set<UUID> = []
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    LogsTableView(
                        selectedLogIds: $selectedLogIds
                    )
                }
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
                
                // NOTE: Don't delete this comment. It's a placeholder for the export/import menu.  
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
                
                // NOTE: Don't delete this comment. It's a placeholder for the filter menu.  
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
            .sheet(item: $viewModel.selectedLogForEdit) { log in
                EditLogView(log: log, viewModel: viewModel)
            }
        }
    }
}

struct LogGroup: Identifiable {
    let id: Date
    let logs: [CalendarEventLog]
}

struct LogsTableView: View {
    @ObservedObject private var viewModel = CalendarEventLogViewModel.shared
    @Binding var selectedLogIds: Set<UUID>
    @State private var logToDelete: CalendarEventLog?
    
    private var groupedLogs: [LogGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.logs) { log in
            calendar.startOfDay(for: log.startDate)
        }
        return grouped.map { LogGroup(id: $0.key, logs: $0.value) }
            .sorted { $0.id > $1.id }
    }
    
    var body: some View {
        ForEach(groupedLogs) { group in
            VStack(alignment: .leading, spacing: 0) {
                Text(group.id.formatted(date: .complete, time: .omitted))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                VStack(spacing: 0) {
                    Table(group.logs) {
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
                                        viewModel.selectedLogForEdit = log
                                    }) {
                                        Label("Edit Event", systemImage: "pencil")
                                    }
                                    
                                    Button(action: {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(log.calendarEventId, forType: .string)
                                    }) {
                                        Label("Copy Event ID", systemImage: "doc.on.doc")
                                    }
                                    
                                    Button(role: .destructive, action: {
                                        logToDelete = log
                                    }) {
                                        Label("Delete Event", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .foregroundStyle(.secondary)
                                }
                                .menuStyle(.borderlessButton)
                                .menuIndicator(.hidden)
                            }
                            .frame(width: 40)
                        }
                        .width(40)
                        
                        TableColumn("Title", value: \.title)
                        TableColumn("Tag Path", value: \.tagPath)
                        TableColumn("Start Time") { log in
                            Text(log.startDate.formatted(date: .omitted, time: .shortened))
                        }
                        TableColumn("Timer End") { log in
                            if let timerEndDate = log.timerEndDate {
                                Text(timerEndDate.formatted(date: .omitted, time: .shortened))
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
                        TableColumn("Expected End Time") { log in
                            Text(log.endDate.formatted(date: .omitted, time: .shortened))
                        }
                        TableColumn("EventId") { log in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: log.tagColor) ?? .gray)
                                    .frame(width: 12, height: 12)
                                Text(log.calendarEventId)
                            }
                        }
                    }
                    .frame(minHeight: 200)
                }
                .overlay(alignment: .topLeading) {
                    if !group.logs.isEmpty {
                        Toggle("", isOn: Binding(
                            get: { group.logs.allSatisfy { selectedLogIds.contains($0.id) } },
                            set: { isSelected in
                                if isSelected {
                                    selectedLogIds.formUnion(group.logs.map { $0.id })
                                } else {
                                    selectedLogIds.subtract(group.logs.map { $0.id })
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
        }
        .background(Color(NSColor.controlBackgroundColor))
        .alert("Delete Event", isPresented: Binding(
            get: { logToDelete != nil },
            set: { if !$0 { logToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let log = logToDelete {
                    viewModel.deleteLog(calendarEventId: log.calendarEventId)
                    selectedLogIds.remove(log.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
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
