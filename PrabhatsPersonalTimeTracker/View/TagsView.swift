import SwiftUI

struct TagsView: View {
    @StateObject private var viewModel = TagsViewModel()
    @State private var showingAddTagSheet = false
    @State private var selectedParentId: UUID?
    @State private var newTagName = ""
    @State private var selectedColor: CatppuccinFrappe = .blue
    @State private var collapsedTags: Set<UUID> = []
    @State private var showingImportSheet = false
    @State private var importText = ""
    @State private var showingExportSheet = false
    @State private var exportText = ""
    @State private var tagToDelete: Tag?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                List {
                    ForEach(viewModel.tags) { tag in
                        TagRow(tag: tag, 
                               level: 0, 
                               collapsedTags: $collapsedTags,
                               selectedParentId: $selectedParentId,
                               showingAddTagSheet: $showingAddTagSheet,
                               viewModel: viewModel, 
                               onColorChange: { newColor in
                            viewModel.updateTagColor(tagId: tag.id, color: newColor)
                        },
                               onDelete: { tag in
                            tagToDelete = tag
                        })
                    }
                }
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        selectedParentId = nil
                        showingAddTagSheet = true
                    }) {
                        Label("Add Tag", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        showingImportSheet = true
                    }) {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        exportText = viewModel.exportTags()
                        showingExportSheet = true
                    }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingAddTagSheet) {
                NavigationStack {
                    Form {
                        TextField("Name", text: $newTagName)
                        CatppuccinColorPicker(selectedColor: $selectedColor)
                    }
                    .navigationTitle("Create New Tag")
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingAddTagSheet = false
                                newTagName = ""
                                selectedColor = .blue
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                viewModel.addTag(name: newTagName, color: selectedColor, parentId: selectedParentId)
                                showingAddTagSheet = false
                                newTagName = ""
                                selectedColor = .blue
                            }
                            .disabled(newTagName.isEmpty)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImportSheet) {
                NavigationStack {
                    VStack {
                        TextEditor(text: $importText)
                            .font(.body.monospaced())
                            .frame(minHeight: 200)
                            .padding()
                            .border(Color.gray.opacity(0.2))
                        
                        Button("Import") {
                            viewModel.importTags(from: importText)
                            showingImportSheet = false
                            importText = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(importText.isEmpty)
                    }
                    .padding()
                    .navigationTitle("Import Tags")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingImportSheet = false
                                importText = ""
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                NavigationStack {
                    VStack {
                        TextEditor(text: .constant(exportText))
                            .font(.body.monospaced())
                            .frame(minHeight: 200)
                            .padding()
                            .border(Color.gray.opacity(0.2))
                            .disabled(true)
                        
                        Button("Copy to Clipboard") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(exportText, forType: .string)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .navigationTitle("Export Tags")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") {
                                showingExportSheet = false
                                exportText = ""
                            }
                        }
                    }
                }
            }
            .sheet(item: $tagToDelete) { tag in
                NavigationStack {
                    VStack(spacing: 20) {
                        Text("Delete Tag")
                            .font(.title)
                            .padding(.top)
                        
                        Text("Are you sure you want to delete '\(tag.name)'?")
                            .font(.body)
                        
                        if !tag.children.isEmpty {
                            Text("This will also delete \(tag.children.count) child tag(s).")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                tagToDelete = nil
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Delete", role: .destructive) {
                                viewModel.deleteTag(tagId: tag.id)
                                tagToDelete = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top)
                    }
                    .padding()
                    .frame(minWidth: 300)
                }
            }
        }
    }
}

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
                            // .font(.caption)
                            // .padding(.horizontal, 6)
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
                TagRow(tag: child, level: level + 1, collapsedTags: $collapsedTags, selectedParentId: $selectedParentId, showingAddTagSheet: $showingAddTagSheet, viewModel: viewModel, onColorChange: onColorChange, onDelete: onDelete)
            }
        }
    }
}

struct CatppuccinColorPicker: View {
    @Binding var selectedColor: CatppuccinFrappe
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        VStack(spacing: 4) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(CatppuccinFrappe.allCases.prefix(8)), id: \.self) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                        )
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
            .frame(maxWidth: 200)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(CatppuccinFrappe.allCases.suffix(6)), id: \.self) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                        )
                        .onTapGesture {
                            selectedColor = color
                        }
                }
            }
            .frame(maxWidth: 200)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TagsView()
//    CatppuccinColorPicker(selectedColor: Binding(
//        get: { CatppuccinFrappe.blue },
//        set: { _ in }
//    ))
}
