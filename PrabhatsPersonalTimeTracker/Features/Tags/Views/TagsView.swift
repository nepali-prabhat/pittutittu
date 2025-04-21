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
                ExportTagsView(text: exportText) {
                    showingExportSheet = false
                    exportText = ""
                }
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

