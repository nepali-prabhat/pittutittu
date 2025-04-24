import Foundation
import CoreData

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
    
    func addLog(calendarEventId: String, title: String, startDate: Date, endDate: Date, timerEndDate: Date? = nil, tagPath: String, tagColor: String) {
        let log = CalendarEventLog(
            calendarEventId: calendarEventId,
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
            }
        } catch {
            print("Error stopping log: \(error)")
        }
    }
} 