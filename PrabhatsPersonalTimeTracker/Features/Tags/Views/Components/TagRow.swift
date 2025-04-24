import SwiftUI

struct TagRow: View {
    let tag: Tag
    let level: Int
    @Binding var collapsedTags: Set<UUID>
    @Binding var selectedParentId: UUID?
    @Binding var showingAddTagSheet: Bool
    let viewModel: TagsViewModel
    let tagPath: String
    var onColorChange: ((CatppuccinFrappe) -> Void)?
    var onDelete: ((Tag) -> Void)?
    var onEdit: ((Tag) -> Void)?
    @State private var isHovered = false
    @State private var isTargeted = false
    @State private var isDragging = false
    @State private var showingCalendarEventSheet = false
    
    private var isCollapsed: Bool {
        collapsedTags.contains(tag.id)
    }
    
    private func toggleCollapse() {
        if collapsedTags.contains(tag.id) {
            collapsedTags.remove(tag.id)
        } else {
            collapsedTags.insert(tag.id)
        }
    }
    
    private func collapseAllChildren() {
        var tagsToCollapse = Set<UUID>()
        func collectChildren(_ tag: Tag) {
            for child in tag.children {
                tagsToCollapse.insert(child.id)
                collectChildren(child)
            }
        }
        collectChildren(tag)
        collapsedTags.formUnion(tagsToCollapse)
    }
    
    private func expandAllChildren() {
        var tagsToExpand = Set<UUID>()
        func collectChildren(_ tag: Tag) {
            for child in tag.children {
                tagsToExpand.insert(child.id)
                collectChildren(child)
            }
        }
        collectChildren(tag)
        collapsedTags.subtract(tagsToExpand)
    }
    
    private var areAllChildrenCollapsed: Bool {
        guard !tag.children.isEmpty else { return false }
        func checkChildren(_ tag: Tag) -> Bool {
            for child in tag.children {
                if !collapsedTags.contains(child.id) {
                    return false
                }
                if !checkChildren(child) {
                    return false
                }
            }
            return true
        }
        return checkChildren(tag)
    }
    
    @ViewBuilder
    private var tagActions: some View {
        Button(action: {
            showingCalendarEventSheet = true
        }) {
            Label("Start Timer", systemImage: "play.circle.fill")
        }
        
        Divider()
        
        Button(action: {
            selectedParentId = tag.id
            showingAddTagSheet = true
        }) {
            Label("Add Child Tag", systemImage: "plus.circle.fill")
        }
        
        Button(action: {
            onEdit?(tag)
        }) {
            Label("Edit", systemImage: "pencil.circle.fill")
        }
        
        Button(role: .destructive, action: {
            onDelete?(tag)
        }) {
            Label("Delete", systemImage: "trash.circle.fill")
        }
        
        if !tag.children.isEmpty {
            Divider()
            Button(action: toggleCollapse) {
                Label(isCollapsed ? "Expand" : "Collapse", systemImage: isCollapsed ? "chevron.down" : "chevron.right")
            }
            if !areAllChildrenCollapsed { 
                Button(action: collapseAllChildren) {
                    Label("Collapse All Children", systemImage: "chevron.down.2")
                }
            }else{
                Button(action: expandAllChildren) {
                    Label("Expand All Children", systemImage: "chevron.up.2")
                }
            }
        }
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                if !tag.children.isEmpty {
                       Button(action: toggleCollapse) {
                           Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                               .foregroundColor(.secondary)
                       }.buttonStyle(.accessoryBar)
                   }
                Text(tag.name)
                    .font(.title3)
            }
            .padding(.leading, CGFloat(level * 20))
            
            Spacer()

             

            Rectangle()
                    .fill(tag.color.color)
                    .frame(width: 4, height: 12)
                    .cornerRadius(2)
        }
        .padding(.trailing, 2)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            tagActions
        }
        .sheet(isPresented: $showingCalendarEventSheet) {
            CalendarEventView(
                eventTitle: "",
                eventStartDate: Date(),
                eventEndDate: Date().addingTimeInterval(3600),
                eventNotes: "",
                eventColor: tag.color.color,
                tagPath: tagPath
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isTargeted ? Color.accentColor.opacity(0.1) : isHovered ? Color.secondary.opacity(0.1) : Color.clear)
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .onDrop(of: [.text], isTargeted: $isTargeted) { providers in
            // Reset dragging state
            isDragging = false
            
            guard let provider = providers.first else { return false }
            provider.loadDataRepresentation(forTypeIdentifier: "public.text") { data, error in
                if let data = data,
                   let string = String(data: data, encoding: .utf8),
                   let draggedTagId = UUID(uuidString: string) {
                    DispatchQueue.main.async {
                        if viewModel.canMoveTag(tagId: draggedTagId, toParentId: tag.id) {
                            viewModel.moveTag(tagId: draggedTagId, newParentId: tag.id)
                        } else if let draggedTag = viewModel.tags.first(where: { $0.id == draggedTagId }) {
                            // If we can't move to a new parent, try to reorder within the same parent
                            viewModel.reorderTag(tagId: draggedTagId, newIndex: tag.index)
                        }
                    }
                }
            }
            return true
        }
        .onDrag {
            isDragging = true
            return NSItemProvider(object: tag.id.uuidString as NSString)
        } preview: {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.accentColor)
                Text(tag.name)
            }
            .padding(8)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
        }
        
        if !tag.children.isEmpty && !isCollapsed {
            ForEach(tag.children) { child in
                TagRow(tag: child, 
                       level: level + 1, 
                       collapsedTags: $collapsedTags,
                       selectedParentId: $selectedParentId,
                       showingAddTagSheet: $showingAddTagSheet,
                       viewModel: viewModel,
                       tagPath: tagPath + " > " + child.name,
                       onColorChange: onColorChange,
                       onDelete: onDelete,
                       onEdit: onEdit)
            }
        }
    }
} 

#Preview {
    let previewTag = Tag(
        id: UUID(),
        name: "Work",
        color: .blue,
        children: [
            Tag(id: UUID(), name: "Meetings", color: .red),
            Tag(id: UUID(), name: "Projects", color: .green, children: [
                Tag(id: UUID(), name: "Project A", color: .yellow)
            ])
        ]
    )
    
    return TagRow(
        tag: previewTag,
        level: 0,
        collapsedTags: .constant([]),
        selectedParentId: .constant(nil),
        showingAddTagSheet: .constant(false),
        viewModel: TagsViewModel(),
        tagPath: "Work > Meetings > Projects > Project A",
        onColorChange: { _ in },
        onDelete: { _ in },
        onEdit: { _ in }
    )
}
