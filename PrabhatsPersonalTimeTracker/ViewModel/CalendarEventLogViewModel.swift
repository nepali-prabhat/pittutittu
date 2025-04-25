import Foundation
import CoreData
import EventKit

@MainActor
class CalendarEventLogViewModel: ObservableObject {
    @Published var logs: [CalendarEventLog] = []
    let context = CoreDataManager.shared.viewContext
    
    init() {
        loadLogs()
    }
    
    func loadLogs() {
        let fetchRequest: NSFetchRequest<CalendarEventLogEntity> = CalendarEventLogEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            logs = entities.map { CalendarEventLog(from: $0) }
        } catch {
            print("Error loading calendar event logs: \(error)")
        }
    }
    
    func addLog(calendarEventId: String, calendarIdentifier: String, title: String, startDate: Date, endDate: Date, timerEndDate: Date? = nil, tagPath: String, tagColor: String) {
        let log = CalendarEventLog(
            calendarEventId: calendarEventId,
            calendarIdentifier: calendarIdentifier,
            title: title,
            startDate: startDate,
            endDate: endDate,
            timerEndDate: timerEndDate,
            tagPath: tagPath,
            tagColor: tagColor
        )
        
        _ = log.toEntity(in: context)
        CoreDataManager.shared.saveContext()
        loadLogs()
    }
    
    func stopLog(calendarEventId: String) {
        let fetchRequest: NSFetchRequest<CalendarEventLogEntity> = CalendarEventLogEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "calendarEventId == %@", calendarEventId)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.timerEndDate = Date()
                CoreDataManager.shared.saveContext()
                loadLogs()
                
                // Update the calendar event
                updateCalendarEvent(calendarEventId: calendarEventId, endDate: Date())
            }
        } catch {
            print("Error stopping log: \(error)")
        }
    }
    
    private func updateCalendarEvent(calendarEventId: String, endDate: Date) {
        let eventStore = EKEventStore()
        
        // Get the event directly using the event ID
        if let event = eventStore.event(withIdentifier: calendarEventId) {
            // Update the event's end date
            event.endDate = endDate
            
            do {
                try eventStore.save(event, span: .thisEvent)
                print("Successfully updated calendar event")
            } catch {
                print("Error updating calendar event: \(error)")
            }
        } else {
            print("Could not find calendar event with ID: \(calendarEventId)")
        }
    }
    
    func deleteLog(calendarEventId: String) {
        let fetchRequest: NSFetchRequest<CalendarEventLogEntity> = CalendarEventLogEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "calendarEventId == %@", calendarEventId)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                CoreDataManager.shared.saveContext()
                loadLogs()
            }
        } catch {
            print("Error deleting log: \(error)")
        }
    }
} 
