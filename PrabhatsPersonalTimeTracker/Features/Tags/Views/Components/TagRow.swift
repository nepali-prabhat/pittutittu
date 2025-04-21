import SwiftUI

struct TagRow: View {
    let tag: Tag
    let level: Int
    @Binding var collapsedTags: Set<UUID>
    @Binding var selectedParentId: UUID?
    @Binding var showingAddTagSheet: Bool
    let viewModel: TagsViewModel
    var onColorChange: ((CatppuccinFrappe) -> Void)?
    var onDelete: ((Tag) -> Void)?
    @State private var isHovered = false
    @State private var isTargeted = false
    @State private var isDragging = false
    
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
            // Play action
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
            // Edit action
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
            HStack {
                if !tag.children.isEmpty {
                    Button(action: toggleCollapse) {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .foregroundColor(.secondary)
                    }.buttonStyle(.accessoryBar)
                }
                Text(tag.name)
                    .font(.title3)
            }
            .padding(.leading, CGFloat(level * 32))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            tagActions
        }
        .listRowSeparator(.hidden)
        .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
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
                       onColorChange: onColorChange,
                       onDelete: onDelete)
            }
        }
    }
} 