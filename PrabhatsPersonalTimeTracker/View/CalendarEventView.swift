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
            Section(header: Text("Event Details")) {
                TextField("Event Title", text: $eventTitle)
                DatePicker("Start Date", selection: $eventStartDate)
                DatePicker("End Date", selection: $eventEndDate)
                TextEditor(text: $eventNotes)
                    .frame(height: 100)
            }
            
            Section(header: Text("Calendar")) {
                Picker("Select Calendar", selection: $selectedCalendarIdentifier) {
                    ForEach(availableCalendars, id: \.calendarIdentifier) { calendar in
                        Text(calendar.title)
                            .tag(calendar.calendarIdentifier)
                    }
                }
                .onChange(of: selectedCalendarIdentifier) { newValue in
                    UserDefaultsManager.shared.saveSelectedCalendar(newValue)
                }
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create Event") {
                    if hasCalendarAccess {
                        createEvent()
                    } else {
                        requestCalendarAccess()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(eventTitle.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 400)
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
        """
        event.notes = (event.notes ?? "") + tagInfo
        
        do {
            try eventStore.save(event, span: .thisEvent)
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
}

#Preview {
    CalendarEventView()
} 
