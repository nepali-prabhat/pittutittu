import Foundation
import CoreData

@MainActor
class TagsViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    let context = CoreDataManager.shared.viewContext
    
    init() {
        loadTags()
    }
    
    func loadTags() {
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
    
    func updateTag(tagId: UUID, name: String, color: CatppuccinFrappe) {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                entity.name = name
                entity.color = color.rawValue
                CoreDataManager.shared.saveContext()
                loadTags()
            }
        } catch {
            print("Error updating tag: \(error)")
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
                    // Get all children of the new parent
                    let childrenFetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                    childrenFetchRequest.predicate = NSPredicate(format: "parent == %@", newParentEntity)
                    childrenFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                    
                    let siblings = try context.fetch(childrenFetchRequest)
                    
                    // Set the new index to be at the end
                    tagEntity.index = Int32(siblings.count)
                    tagEntity.parent = newParentEntity
                    
                    CoreDataManager.shared.saveContext()
                    loadTags()
                }
            }
        } catch {
            print("Error moving tag: \(error)")
        }
    }
    
    func reorderTag(tagId: UUID, newIndex: Int) {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
        
        do {
            if let tagEntity = try context.fetch(fetchRequest).first,
               let parent = tagEntity.parent {
                // Get all siblings
                let siblingsFetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                siblingsFetchRequest.predicate = NSPredicate(format: "parent == %@", parent)
                siblingsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
                
                var siblings = try context.fetch(siblingsFetchRequest)
                
                // Remove the tag from its current position
                siblings.removeAll { $0.id == tagId }
                
                // Insert at new position
                siblings.insert(tagEntity, at: min(newIndex, siblings.count))
                
                // Update indices
                for (index, sibling) in siblings.enumerated() {
                    sibling.index = Int32(index)
                }
                
                CoreDataManager.shared.saveContext()
                loadTags()
            }
        } catch {
            print("Error reordering tag: \(error)")
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
                        return true // Allow moving to any ancestor
                    }
                    currentParent = parent.parent
                }
                
                // Check if the target parent is a descendant of the tag
                let targetFetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                targetFetchRequest.predicate = NSPredicate(format: "id == %@", toParentId as CVarArg)
                
                if let targetEntity = try context.fetch(targetFetchRequest).first {
                    var currentParent = targetEntity.parent
                    while let parent = currentParent {
                        if parent.id == tagId {
                            return false // Prevent moving to a descendant
                        }
                        currentParent = parent.parent
                    }
                }
                
                return true
            }
        } catch {
            print("Error checking tag move: \(error)")
        }
        
        return false
    }
    
    func deleteTag(tagId: UUID) {
        let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", tagId as CVarArg)
        
        do {
            if let entity = try context.fetch(fetchRequest).first {
                context.delete(entity)
                CoreDataManager.shared.saveContext()
                loadTags()
            }
        } catch {
            print("Error deleting tag: \(error)")
        }
    }
} 