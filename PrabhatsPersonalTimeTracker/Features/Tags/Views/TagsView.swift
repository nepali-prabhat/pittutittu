import SwiftUI

struct TagsView: View {
    @StateObject private var viewModel = TagsViewModel()
    @State private var showingAddTagSheet = false
    @State private var selectedParentId: UUID?
    @State private var newTagName = ""
    @State private var selectedColor: CatppuccinFrappe = .blue
    @State private var collapsedTags: Set<UUID> = UserDefaultsManager.shared.loadCollapsedTags()
    @State private var showingImportSheet = false
    @State private var importText = ""
    @State private var showingExportSheet = false
    @State private var exportText = ""
    @State private var tagToDelete: Tag?
    @State private var tagToEdit: Tag?
    @State private var editTagName = ""
    @State private var editTagColor: CatppuccinFrappe = .blue
    @State private var showingDeleteAllConfirmation = false
    @State private var showingImportConfirmation = false
    
    private func getTagPath(for tag: Tag, in tags: [Tag]) -> String {
        var path: [String] = []
        
        func findPath(currentTag: Tag, targetId: UUID, currentPath: [String]) -> [String]? {
            if currentTag.id == targetId {
                return currentPath + [currentTag.name]
            }
            
            for child in currentTag.children {
                if let foundPath = findPath(currentTag: child, targetId: targetId, currentPath: currentPath + [currentTag.name]) {
                    return foundPath
                }
            }
            
            return nil
        }
        
        for rootTag in tags {
            if let foundPath = findPath(currentTag: rootTag, targetId: tag.id, currentPath: []) {
                path = foundPath
                break
            }
        }
        
        return path.joined(separator: " > ")
    }
    
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
                               tagPath: getTagPath(for: tag, in: viewModel.tags),
                               onColorChange: { newColor in
                            viewModel.updateTagColor(tagId: tag.id, color: newColor)
                        },
                               onDelete: { tag in
                            tagToDelete = tag
                        },
                               onEdit: { tag in
                            tagToEdit = tag
                            editTagName = tag.name
                            editTagColor = tag.color
                        })
                    }
                }
                .listRowSeparator(.hidden)
                .onChange(of: collapsedTags) { newValue in
                    UserDefaultsManager.shared.saveCollapsedTags(newValue)
                }
                .contextMenu(forSelectionType: Tag.self) { items in
                    // This is needed to prevent the default context menu
                } primaryAction: { items in
                    // This is needed to prevent the default context menu
                }
            }
            .navigationTitle("Tags")
            .contextMenu {
                Button(action: {
                    selectedParentId = nil
                    showingAddTagSheet = true
                }) {
                    Label("Add Tag", systemImage: "plus")
                }
                
                Button(role: .destructive, action: {
                    showingDeleteAllConfirmation = true
                }) {
                    Label("Delete All Tags", systemImage: "trash")
                }
                
                Divider()
                
                Button(action: {
                    collapsedTags.removeAll()
                }) {
                    Label("Expand All", systemImage: "chevron.down.2")
                }
                
                Button(action: {
                    var allIds = Set<UUID>()
                    for tag in viewModel.tags {
                        func collectIds(_ tag: Tag) {
                            allIds.insert(tag.id)
                            for child in tag.children {
                                collectIds(child)
                            }
                        }
                        collectIds(tag)
                    }
                    collapsedTags = allIds
                }) {
                    Label("Collapse All", systemImage: "chevron.up.2")
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    ImportExportMenu(
                        showingImportSheet: $showingImportSheet,
                        showingExportSheet: $showingExportSheet,
                        importText: $importText,
                        exportText: $exportText,
                        onExport: { viewModel.exportTags() }
                    )
                }
                
                ToolbarItem(placement: .automatic) {
                    ExpandCollapseMenu(
                        collapsedTags: $collapsedTags,
                        tags: viewModel.tags
                    )
                }

                 ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        selectedParentId = nil
                        showingAddTagSheet = true
                    }) {
                        Label("Add Tag", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTagSheet) {
                AddTagView(
                    name: $newTagName,
                    color: $selectedColor,
                    parentId: selectedParentId,
                    onAdd: { name, color, parentId in
                        viewModel.addTag(name: name, color: color, parentId: parentId)
                        showingAddTagSheet = false
                        newTagName = ""
                        selectedColor = .blue
                    }
                )
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportTagsView(
                    text: $importText,
                    onImport: { text in
                        showingImportSheet = false
                        importText = text // Store the text temporarily
                        showingImportConfirmation = true
                    }
                )
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportTagsView(
                    text: exportText,
                    onDone: {
                        showingExportSheet = false
                        exportText = ""
                    },
                    onReset: {
                        exportText = viewModel.exportTags()
                    }
                )
            }
            .sheet(item: $tagToDelete) { tag in
                DeleteTagConfirmationView(
                    tag: tag,
                    onDelete: {
                        viewModel.deleteTag(tagId: tag.id)
                        tagToDelete = nil
                    },
                    onCancel: {
                        tagToDelete = nil
                    }
                )
            }
            .sheet(item: $tagToEdit) { tag in
                EditTagView(
                    name: $editTagName,
                    color: $editTagColor,
                    onSave: {
                        viewModel.updateTag(tagId: tag.id, name: editTagName, color: editTagColor)
                        tagToEdit = nil
                    }
                )
            }
            .alert("Delete All Tags?", isPresented: $showingDeleteAllConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Move the delete logic here
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TagEntity.fetchRequest()
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    
                    do {
                        try viewModel.context.execute(deleteRequest)
                        CoreDataManager.shared.saveContext()
                        viewModel.loadTags()
                    } catch {
                        print("Error deleting all tags: \(error)")
                    }
                }
            } message: {
                Text("This action cannot be undone. Are you sure you want to delete all tags?")
            }
            .alert("Import Tags", isPresented: $showingImportConfirmation) {
                Button("Cancel", role: .cancel) {
                    importText = "" // Clear the stored text
                }
                Button("Replace", role: .destructive) {
                    viewModel.importTags(from: importText)
                    importText = "" // Clear the stored text
                }
            } message: {
                Text("This will delete all existing tags and replace them with the imported tags. This action cannot be undone. Do you want to continue?")
            }
            .onAppear {
                exportText = viewModel.exportTags()
            }
        }
    }
} 

