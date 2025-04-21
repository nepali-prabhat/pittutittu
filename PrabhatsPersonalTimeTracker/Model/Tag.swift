import Foundation
import CoreData

struct Tag: Identifiable {
    let id: UUID
    var name: String
    var color: CatppuccinFrappe
    var children: [Tag]
    
    init(id: UUID = UUID(), name: String, color: CatppuccinFrappe, children: [Tag] = []) {
        self.id = id
        self.name = name
        self.color = color
        self.children = children
    }
    
    init(from entity: TagEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? ""
        self.color = CatppuccinFrappe(rawValue: entity.color ?? "") ?? .blue
        self.children = (entity.children?.allObjects as? [TagEntity])?.map { Tag(from: $0) } ?? []
    }
    
    func toEntity(in context: NSManagedObjectContext) -> TagEntity {
        let entity = TagEntity(context: context)
        entity.id = id
        entity.name = name
        entity.color = color.rawValue
        
        // Handle children
        for child in children {
            let childEntity = child.toEntity(in: context)
            childEntity.parent = entity
        }
        
        return entity
    }
} 