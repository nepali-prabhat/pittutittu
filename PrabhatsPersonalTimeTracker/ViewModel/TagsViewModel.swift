import Foundation
import SwiftUI

@MainActor
class TagsViewModel: ObservableObject {
    @Published var tags: [Tag] = []
    
    init() {
        // Initialize with some sample data
        tags = [
            Tag(name: "University", color: .red, children: [
                Tag(name: "USA", color: .blue, children: [
                    Tag(name: "CMU", color: .green, children: [
                        Tag(name: "canvas course", color: .peach, children: [
                            Tag(name: "INI Graduate Onboarding 2025", color: .mauve)
                        ]),
                        Tag(name: "communication", color: .pink)
                    ])
                ]),
                Tag(name: "Europe", color: .yellow, children: [
                    Tag(name: "Germany", color: .teal, children: [
                        Tag(name: "TU Dresden", color: .sky, children: [
                            Tag(name: "Application", color: .maroon)
                        ]),
                        Tag(name: "FAU", color: .sapphire),
                        Tag(name: "LMU", color: .sky)
                    ]),
                    Tag(name: "Luxembourg", color: .teal, children: [
                        Tag(name: "TUL", color: .sky, children: [
                            Tag(name: "Application", color: .maroon)
                        ])
                    ])
                ])
            ]),
            Tag(name: "Language", color: .yellow, children: [
                Tag(name: "German", color: .teal, children: [
                    Tag(name: "DUO lingo", color: .sky)
                ])
            ])
        ]
    }
    
    func addTag(name: String, color: CatppuccinFrappe, parentId: UUID?) {
        let newTag = Tag(name: name, color: color, parentId: parentId)
        if let parentId = parentId {
            updateTagInTree(tag: newTag, parentId: parentId)
        } else {
            tags.append(newTag)
        }
    }
    
    func updateTagColor(tagId: UUID, color: CatppuccinFrappe) {
        func update(_ tags: inout [Tag]) -> Bool {
            for i in 0..<tags.count {
                if tags[i].id == tagId {
                    var updatedTag = tags[i]
                    updatedTag.color = color
                    tags[i] = updatedTag
                    return true
                }
                if update(&tags[i].children) {
                    return true
                }
            }
            return false
        }
        
        var mutableTags = tags
        _ = update(&mutableTags)
        tags = mutableTags
    }
    
    private func updateTagInTree(tag: Tag, parentId: UUID) {
        func update(_ tags: inout [Tag]) -> Bool {
            for i in 0..<tags.count {
                if tags[i].id == parentId {
                    var updatedTag = tags[i]
                    updatedTag.children.append(tag)
                    tags[i] = updatedTag
                    return true
                }
                if update(&tags[i].children) {
                    return true
                }
            }
            return false
        }
        
        var mutableTags = tags
        _ = update(&mutableTags)
        tags = mutableTags
    }
    
    func moveTag(tagId: UUID, newParentId: UUID?) {
        // Implementation for moving tags will be added later
    }
} 