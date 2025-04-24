import SwiftUI
import EventKit

struct CalendarEventView: View {
    @State private var eventTitle: String
    @State private var eventStartDate: Date
    @State private var eventEndDate: Date
    @State private var eventNotes: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasCalendarAccess = false
    @State private var showingPermissionAlert = false
    @State private var availableCalendars: [EKCalendar] = []
    @State private var selectedCalendarIdentifier: String
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logViewModel = CalendarEventLogViewModel()
    @FocusState private var isTitleFocused: Bool
    
    private let eventStore = EKEventStore()
    private let eventColor: Color
    private let tagPath: String
    
    init(eventTitle: String = "", eventStartDate: Date = Date(), eventEndDate: Date = Date().addingTimeInterval(3600), eventNotes: String = "", eventColor: Color = .blue, tagPath: String = "") {
        _eventTitle = State(initialValue: eventTitle)
        _eventStartDate = State(initialValue: eventStartDate)
        _eventEndDate = State(initialValue: eventEndDate)
        _eventNotes = State(initialValue: eventNotes)
        self.eventColor = eventColor
        self.tagPath = tagPath
        
        // Initialize selected calendar from UserDefaults
        if let savedCalendarId = UserDefaultsManager.shared.loadSelectedCalendar() {
            _selectedCalendarIdentifier = State(initialValue: savedCalendarId)
        } else {
            _selectedCalendarIdentifier = State(initialValue: "")
        }
    }
    
    var body: some View {
        Form {
            
            
            Section(header: Text("Calendar")) {
                Picker("Calendar", selection: $selectedCalendarIdentifier) {
                    ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                        Text(calendar.title)
                            .tag(calendar.calendarIdentifier)
                    }
                }
                .onChange(of: selectedCalendarIdentifier) { newValue in
                    UserDefaultsManager.shared.saveSelectedCalendar(newValue)
                }
            }
            
            Section(header: Text("Event Details")) {
                TextField("Event Title", text: $eventTitle)
                    .focused($isTitleFocused)
                DatePicker("Start Date", selection: $eventStartDate)
                DatePicker("End Date", selection: $eventEndDate)
                
                HStack(spacing: 8) {
                    ForEach([15, 30, 45, 60, 90, 120], id: \.self) { minutes in
                        Button(action: {
                            eventEndDate = eventStartDate.addingTimeInterval(TimeInterval(minutes * 60))
                        }) {
                            Text(formatDuration(minutes))
                                .font(.system(size: 12))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
                
                TextEditor(text: $eventNotes)
                    .frame(height: 100)
                    .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
            }
        }
        .padding()
        // .frame(width: 400, height: 400)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Create Event") {
                    if hasCalendarAccess {
                        createEvent()
                    } else {
                        requestCalendarAccess()
                    }
                }
                .disabled(eventTitle.isEmpty)
            }
        }
        .alert("Event Creation", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(alertMessage)
        }
        .alert("Calendar Access Required", isPresented: $showingPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please grant calendar access in System Settings to create events.")
        }
        .onAppear {
            checkCalendarAccess()
            loadCalendars()
            isTitleFocused = true
        }
    }
    
    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = status == .fullAccess
    }
    
    private func loadCalendars() {
        availableCalendars = eventStore.calendars(for: .event)
        
        // If no calendar is selected and we have calendars available, select the first one
        if selectedCalendarIdentifier.isEmpty && !availableCalendars.isEmpty {
            selectedCalendarIdentifier = availableCalendars[0].calendarIdentifier
            UserDefaultsManager.shared.saveSelectedCalendar(selectedCalendarIdentifier)
        }
    }
    
    private func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if granted {
                    hasCalendarAccess = true
                    loadCalendars()
                    createEvent()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func getOrCreateTagCalendar() -> EKCalendar? {
        // Create a unique calendar name based on the tag's color
        let tagCalendarTitle = "Tag Events - \(eventColor.description)"
        
        // Try to find existing calendar for this color
        if let existingCalendar = eventStore.calendars(for: .event).first(where: { $0.title == tagCalendarTitle }) {
            return existingCalendar
        }
        
        // Get the source from the selected calendar
        guard let selectedCalendar = eventStore.calendar(withIdentifier: selectedCalendarIdentifier),
              let source = selectedCalendar.source else {
            return nil
        }
        
        // Create new calendar if none exists
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = tagCalendarTitle
        calendar.source = source
        
        // Set the calendar color
        if let cgColor = eventColor.cgColor {
            calendar.cgColor = cgColor
        }
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return calendar
        } catch {
            print("Error creating tag calendar: \(error)")
            return nil
        }
    }
    
    private func createEvent() {
        let event = EKEvent(eventStore: eventStore)
        let eventId = UUID().uuidString
        event.title = eventTitle
        event.startDate = eventStartDate
        event.endDate = eventEndDate
        event.notes = eventNotes
        
        // Set the event's calendar to the selected calendar
        if let calendar = eventStore.calendar(withIdentifier: selectedCalendarIdentifier) {
            event.calendar = calendar
        } else {
            event.calendar = eventStore.defaultCalendarForNewEvents
        }
        
        // Add tag information to the event's notes
        let tagInfo = """
        
        Tag Path: \(tagPath)
        Tag Color: \(eventColor.description)
        Event ID: \(eventId)
        """
        event.notes = (event.notes ?? "") + tagInfo
        
        do {
            try eventStore.save(event, span: .thisEvent)
            
            // Save the log
            logViewModel.addLog(
                calendarEventId: eventId,
                title: eventTitle,
                startDate: eventStartDate,
                endDate: eventEndDate,
                timerEndDate: nil, // This will be set when the timer is stopped
                tagPath: tagPath,
                tagColor: eventColor.description
            )
            
            alertMessage = "Event created successfully!"
            showAlert = true
            resetForm()
        } catch {
            alertMessage = "Error creating event: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    private func resetForm() {
        eventTitle = ""
        eventStartDate = Date()
        eventEndDate = Date().addingTimeInterval(3600)
        eventNotes = ""
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else if minutes == 60 {
            return "1h"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

#Preview {
    CalendarEventView()
} 
