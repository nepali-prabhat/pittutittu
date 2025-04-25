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
                VStack(alignment: .leading, spacing: 20) {
                    // Welcome message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome, Prabhat!")
                            .font(.largeTitle)
                            .bold()
                        Text("Track your time and stay productive")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if activeLogs.isEmpty {
                        // Empty state
                        VStack(spacing: 12) {
                            Image(systemName: "clock.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("No Active Events")
                                .font(.title2)
                                .bold()
                            
                            Text("Start tracking your time by creating a new event")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        // Active events horizontal list
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(activeLogs) { log in
                                    ActiveTagCard(log: log, onStop: {
                                        viewModel.stopLog(calendarEventId: log.calendarEventId)
                                    })
                                    .frame(width: 300)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Create New Event button
                    HStack {
                        Spacer()
                        Button(action: {
                            navigateToTags = true
                        }) {
                            Label("track new event", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .navigationTitle("Active Events")
            .navigationDestination(isPresented: $navigateToTags) {
                TagsView(onEventCreated: {
                    navigateToTags = false
                })
            }
        }
    }
}

struct ActiveTagCard: View {
    let log: CalendarEventLog
    let onStop: () -> Void
    @State private var showingStopConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with tag and title
            HStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: log.tagColor) ?? .gray)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.tagPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(log.title)
                        .font(.headline)
                }
            }
            
            // Duration display
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDuration(from: log.startDate, to: Date()))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Text("Expected: \(formatDuration(from: log.startDate, to: log.endDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // DateTime information
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(log.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                
                HStack {
                    Text("Ends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(log.endDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    // View action
                }) {
                    Label("View", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.blue)
                
                Button(action: {
                    // Edit action
                }) {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                
                Button(action: {
                    showingStopConfirmation = true
                }) {
                    Label("Stop", systemImage: "stop.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .alert("Stop Event?", isPresented: $showingStopConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Stop", role: .destructive) {
                onStop()
            }
        } message: {
            Text("Are you sure you want to stop this event? This action cannot be undone.")
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
    ActiveView()
} 
