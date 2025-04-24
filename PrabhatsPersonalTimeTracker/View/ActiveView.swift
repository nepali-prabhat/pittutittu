import SwiftUI

struct ActiveView: View {
    @StateObject private var viewModel = CalendarEventLogViewModel()
    @State private var showingCalendarEventSheet = false
    @State private var navigateToTags = false
    
    private var activeLogs: [CalendarEventLog] {
        viewModel.logs.filter { $0.timerEndDate == nil }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 16)], spacing: 16) {
                    ForEach(activeLogs) { log in
                        ActiveTagCard(log: log, onStop: {
                            viewModel.stopLog(calendarEventId: log.calendarEventId)
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("Active Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        navigateToTags = true
                    }) {
                        Label("New Task", systemImage: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToTags) {
                TagsView()
            }
        }
    }
}

struct ActiveTagCard: View {
    let log: CalendarEventLog
    let onStop: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: log.tagColor) ?? .gray)
                    .frame(width: 12, height: 12)
                Text(log.tagPath)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(log.title)
                .font(.title2)
                .bold()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(log.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Expected End")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(log.endDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }
            }
            
            HStack {
                Text("Duration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatDuration(from: log.startDate, to: Date()))
                    .font(.subheadline)
                    .monospacedDigit()
            }
            
            Button(action: onStop) {
                Label("Stop", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
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
    ActiveView()
} 