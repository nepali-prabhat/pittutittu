import SwiftUI

struct ExpandCollapseMenu: View {
    @Binding var collapsedTags: Set<UUID>
    let tags: [Tag]
    
    private func collectAllTagIds(_ tag: Tag) -> Set<UUID> {
        var ids = Set<UUID>()
        ids.insert(tag.id)
        for child in tag.children {
            ids.formUnion(collectAllTagIds(child))
        }
        return ids
    }
    
    private var allTagIds: Set<UUID> {
        var ids = Set<UUID>()
        for tag in tags {
            ids.formUnion(collectAllTagIds(tag))
        }
        return ids
    }
    
    var body: some View {
        Menu {
            Button(action: {
                collapsedTags.removeAll()
            }) {
                Label("Expand All", systemImage: "chevron.down.2")
            }
            
            Button(action: {
                collapsedTags.formUnion(allTagIds)
            }) {
                Label("Collapse All", systemImage: "chevron.up.2")
            }
        } label: {
            Label("Expand/Collapse", systemImage: "rectangle.expand.vertical").foregroundStyle(.secondary)
        }
    }
} 