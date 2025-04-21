import Foundation
import CoreData

@MainActor
class TagsViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    private let context = CoreDataManager.shared.viewContext
    
    init() {
        loadTags()
    }
    
    private func loadTags() {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "parent == nil")
        
        do {
            let entities = try context.fetch(fetchRequest)
            tags = entities.map { Tag(from: $0) }
        } catch {
            print("Error loading tags: \(error)")
        }
    }
    
    func importTags(from string: String) {
        let newTags = TagParser.parse(string)
        
        // Clear existing tags
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TagEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            
            // Save new tags
            for tag in newTags {
                _ = tag.toEntity(in: context)
            }
            
            CoreDataManager.shared.saveContext()
            loadTags()
        } catch {
            print("Error importing tags: \(error)")
        }
    }
    
    func exportTags() -> String {
        return TagParser.export(tags)
    }
    
    func addTag(name: String, color: CatppuccinFrappe, parentId: UUID?) {
        let newTag = Tag(name: name, color: color)
        
        if let parentId = parentId {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", parentId as CVarArg)
            
            do {
                if let parentEntity = try context.fetch(fetchRequest).first {
                    let childEntity = newTag.toEntity(in: context)
                    childEntity.parent = parentEntity
                    CoreDataManager.shared.saveContext()
                    loadTags()
                }
            } catch {
                print("Error adding child tag: \(error)")
            }
        } else {
            let entity = newTag.toEntity(in: context)
            CoreDataManager.shared.saveContext()
            loadTags()
        }
    }
    
    func updateTagColor(tagId: UUID, color: CatppuccinFrappe) {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.color = color.rawValue
                CoreDataManager.shared.saveContext()
                loadTags()
            }
        } catch {
            print("Error updating tag color: \(error)")
        }
    }
    
    func moveTag(tagId: UUID, newParentId: UUID) {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
        
        do {
            if let tagEntity = try context.fetch(fetchRequest).first {
                let parentFetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                parentFetchRequest.predicate = NSPredicate(format: "id == %@", newParentId as CVarArg)
                
                if let newParentEntity = try context.fetch(parentFetchRequest).first {
                    tagEntity.parent = newParentEntity
                    CoreDataManager.shared.saveContext()
                    loadTags()
                }
            }
        } catch {
            print("Error moving tag: \(error)")
        }
    }
    
    func canMoveTag(tagId: UUID, toParentId: UUID) -> Bool {
        // Prevent moving a tag to itself or its children
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
        
        do {
            if let tagEntity = try context.fetch(fetchRequest).first {
                // Check if the target parent is the tag itself
                if tagId == toParentId {
                    return false
                }
                
                // Check if the target parent is a child of the tag
                var currentParent = tagEntity.parent
                while let parent = currentParent {
                    if parent.id == toParentId {
                        return false
                    }
                    currentParent = parent.parent
                }
                
                return true
            }
        } catch {
            print("Error checking tag move: \(error)")
        }
        
        return false
    }
} 