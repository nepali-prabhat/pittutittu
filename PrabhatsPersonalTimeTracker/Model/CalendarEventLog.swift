import Foundation
import CoreData

struct CalendarEventLog: Identifiable, Hashable {
    let id: UUID
    let calendarEventId: String
    let calendarIdentifier: String
    let title: String
    let startDate: Date
    let endDate: Date
    let timerEndDate: Date?
    let tagPath: String
    let tagColor: String
    
    init(id: UUID = UUID(), calendarEventId: String, calendarIdentifier: String, title: String, startDate: Date, endDate: Date, timerEndDate: Date? = nil, tagPath: String, tagColor: String) {
        self.id = id
        self.calendarEventId = calendarEventId
        self.calendarIdentifier = calendarIdentifier
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.timerEndDate = timerEndDate
        self.tagPath = tagPath
        self.tagColor = tagColor
    }
    
    init(from entity: CalendarEventLogEntity) {
        self.id = entity.id ?? UUID()
        self.calendarEventId = entity.calendarEventId ?? ""
        self.calendarIdentifier = entity.calendarIdentifier ?? ""
        self.title = entity.title ?? ""
        self.startDate = entity.startDate ?? Date()
        self.endDate = entity.endDate ?? Date()
        self.timerEndDate = entity.timerEndDate
        self.tagPath = entity.tagPath ?? ""
        self.tagColor = entity.tagColor ?? ""
    }
    
    func toEntity(in context: NSManagedObjectContext) -> CalendarEventLogEntity {
        let entity = CalendarEventLogEntity(context: context)
        entity.id = id
        entity.calendarEventId = calendarEventId
        entity.calendarIdentifier = calendarIdentifier
        entity.title = title
        entity.startDate = startDate
        entity.endDate = endDate
        entity.timerEndDate = timerEndDate
        entity.tagPath = tagPath
        entity.tagColor = tagColor
        return entity
    }
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CalendarEventLog, rhs: CalendarEventLog) -> Bool {
        lhs.id == rhs.id
    }
} 