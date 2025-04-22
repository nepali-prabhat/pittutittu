import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let collapsedTagsKey = "collapsedTags"
    
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
} 