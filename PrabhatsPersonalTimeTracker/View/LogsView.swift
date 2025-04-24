import SwiftUI

struct LogsView: View {
    @StateObject private var viewModel = CalendarEventLogViewModel()
    
    var body: some View {
        VStack {
            Text("Time Logs")
                .font(.largeTitle)
                .padding()
            
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
                TableColumn("Tag Color") { log in
                    HStack {
                        Circle()
                            .fill(Color(hex: log.tagColor) ?? .gray)
                            .frame(width: 12, height: 12)
                        Text(log.tagColor)
                    }
                }
            }
            .padding()
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