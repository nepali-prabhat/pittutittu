import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let collapsedTagsKey = "collapsedTags"
    private let selectedCalendarKey = "selectedCalendarIdentifier"
    
    private init() {}
    
    func saveCollapsedTags(_ tagIds: Set<UUID>) {
        let stringIds = tagIds.map { $0.uuidString }
        UserDefaults.standard.set(stringIds, forKey: collapsedTagsKey)
    }
    
    func loadCollapsedTags() -> Set<UUID> {
        guard let stringIds = UserDefaults.standard.stringArray(forKey: collapsedTagsKey) else {
            return []
        }
        return Set(stringIds.compactMap { UUID(uuidString: $0) })
    }
    
    func saveSelectedCalendar(_ calendarIdentifier: String) {
        UserDefaults.standard.set(calendarIdentifier, forKey: selectedCalendarKey)
    }
    
    func loadSelectedCalendar() -> String? {
        return UserDefaults.standard.string(forKey: selectedCalendarKey)
    }
} 