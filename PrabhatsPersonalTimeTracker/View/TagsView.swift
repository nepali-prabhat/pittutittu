import SwiftUI

struct TagsView: View {
    @StateObject private var viewModel = TagsViewModel()
    @State private var showingAddTagSheet = false
    @State private var selectedParentId: UUID?
    @State private var newTagName = ""
    @State private var selectedColor: CatppuccinFrappe = .blue
    @State private var collapsedTags: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.tags) { tag in
                    TagRow(tag: tag, level: 0, collapsedTags: $collapsedTags, onColorChange: { newColor in
                        viewModel.updateTagColor(tagId: tag.id, color: newColor)
                    })
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
        }
    }
}

struct TagRow: View {
    let tag: Tag
    let level: Int
    @Binding var collapsedTags: Set<UUID>
    var onColorChange: ((CatppuccinFrappe) -> Void)?
    
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
    
    var body: some View {
        HStack {
            HStack {
                if !tag.children.isEmpty {
                    Button(action: toggleCollapse) {
                        Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        
                        Text(tag.name)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(tag.name)
                            .font(.title3)
                }
                
                
                
                
                // Text(tag.id.uuidString.prefix(8))
            }
            .padding(.leading, CGFloat(level * 20))
            
            
            Button(action: {
                // Action to be implemented
            }) {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(tag.color.color)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            if !tag.children.isEmpty {
                Text("\(tag.children.count)")
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        
        if !tag.children.isEmpty && !isCollapsed {
            ForEach(tag.children) { child in
                TagRow(tag: child, level: level + 1, collapsedTags: $collapsedTags, onColorChange: onColorChange)
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
