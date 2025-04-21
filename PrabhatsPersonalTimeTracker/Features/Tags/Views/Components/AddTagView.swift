import SwiftUI

struct AddTagView: View {
    @Binding var name: String
    @Binding var color: CatppuccinFrappe
    let parentId: UUID?
    let onAdd: (String, CatppuccinFrappe, UUID?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                CatppuccinColorPicker(selectedColor: $color)
            }
            .navigationTitle("Create New Tag")
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        name = ""
                        color = .blue
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, color, parentId)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 