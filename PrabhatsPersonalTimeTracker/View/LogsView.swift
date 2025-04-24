import SwiftUI

struct LogsView: View {
    @StateObject private var viewModel = CalendarEventLogViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Table(viewModel.logs) {
                    TableColumn("Title", value: \.title)
                    TableColumn("Start Time") { log in
                        Text(log.startDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    TableColumn("End Time") { log in
                        Text(log.endDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    TableColumn("Duration") { log in
                        Text(formatDuration(from: log.startDate, to: log.endDate))
                    }
                    TableColumn("Tag Path", value: \.tagPath)
                    // NOTE: Don't delete this
                    if false {
                        TableColumn("Tag Color") { log in
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: log.tagColor) ?? .gray)
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                // .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
            .navigationTitle("Time Logs")
            .toolbar {
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