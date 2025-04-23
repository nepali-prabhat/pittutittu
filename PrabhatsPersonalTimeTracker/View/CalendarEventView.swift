import SwiftUI
import EventKit

struct CalendarEventView: View {
    @State private var eventTitle: String = ""
    @State private var eventStartDate: Date = Date()
    @State private var eventEndDate: Date = Date().addingTimeInterval(3600)
    @State private var eventNotes: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var hasCalendarAccess = false
    @State private var showingPermissionAlert = false
    
    private let eventStore = EKEventStore()
    
    var body: some View {
        Form {
            Section(header: Text("Event Details")) {
                TextField("Event Title", text: $eventTitle)
                DatePicker("Start Date", selection: $eventStartDate)
                DatePicker("End Date", selection: $eventEndDate)
                TextEditor(text: $eventNotes)
                    .frame(height: 100)
            }
            
            Button("Create Event") {
                if hasCalendarAccess {
                    createEvent()
                } else {
                    requestCalendarAccess()
                }
            }
            .disabled(eventTitle.isEmpty)
        }
        .padding()
        .frame(width: 400, height: 300)
        .alert("Event Creation", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
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
        }
    }
    
    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        hasCalendarAccess = status == .fullAccess
    }
    
    private func requestCalendarAccess() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if granted {
                    hasCalendarAccess = true
                    createEvent()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func createEvent() {
        let event = EKEvent(eventStore: eventStore)
        event.title = eventTitle
        event.startDate = eventStartDate
        event.endDate = eventEndDate
        event.notes = eventNotes
        event.calendar = eventStore.defaultCalendarForNewEvents
        
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