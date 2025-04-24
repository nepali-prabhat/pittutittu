import Foundation
import CoreData

struct CalendarEventLog: Identifiable {
    let id: UUID
    let calendarEventId: String
    let title: String
    let startDate: Date
    let endDate: Date
    let tagPath: String
    let tagColor: String
    
    init(id: UUID = UUID(), calendarEventId: String, title: String, startDate: Date, endDate: Date, tagPath: String, tagColor: String) {
        self.id = id
        self.calendarEventId = calendarEventId
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.tagPath = tagPath
        self.tagColor = tagColor
    }
    
    init(from entity: CalendarEventLogEntity) {
        self.id = entity.id ?? UUID()
        self.calendarEventId = entity.calendarEventId ?? ""
        self.title = entity.title ?? ""
        self.startDate = entity.startDate ?? Date()
        self.endDate = entity.endDate ?? Date()
        self.tagPath = entity.tagPath ?? ""
        self.tagColor = entity.tagColor ?? ""
    }
    
    func toEntity(in context: NSManagedObjectContext) -> CalendarEventLogEntity {
        let entity = CalendarEventLogEntity(context: context)
        entity.id = id
        entity.calendarEventId = calendarEventId
        entity.title = title
        entity.startDate = startDate
        entity.endDate = endDate
        entity.tagPath = tagPath
        entity.tagColor = tagColor
        return entity
    }
} 