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
                    // Delete all tags
                    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TagEntity.fetchRequest()
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    
                    do {
                        try viewModel.context.execute(deleteRequest)
                        CoreDataManager.shared.saveContext()
                        viewModel.loadTags()
                    } catch {
                        print("Error deleting all tags: \(error)")
                    }
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
                        viewModel.importTags(from: text)
                        showingImportSheet = false
                        importText = ""
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
            .onAppear {
                exportText = viewModel.exportTags()
            }
        }
    }
} 

