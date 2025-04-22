import Foundation
import CoreData

struct Tag: Identifiable, Hashable {
    let id: UUID
    var name: String
    var color: CatppuccinFrappe
    var children: [Tag]
    var index: Int
    
    init(id: UUID = UUID(), name: String, color: CatppuccinFrappe, children: [Tag] = [], index: Int = 0) {
        self.id = id
        self.name = name
        self.color = color
        self.children = children
        self.index = index
    }
    
    init(from entity: TagEntity) {
        self.id = entity.id ?? UUID()
        self.name = entity.name ?? ""
        self.color = CatppuccinFrappe(rawValue: entity.color ?? "") ?? .blue
        self.children = (entity.children?.allObjects as? [TagEntity])?.map { Tag(from: $0) } ?? []
        self.index = Int(entity.index)
    }
    
    func toEntity(in context: NSManagedObjectContext) -> TagEntity {
        let entity = TagEntity(context: context)
        entity.id = id
        entity.name = name
        entity.color = color.rawValue
        entity.index = Int32(index)
        
        // Handle children
        for child in children {
            let childEntity = child.toEntity(in: context)
            childEntity.parent = entity
        }
        
        return entity
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
} 