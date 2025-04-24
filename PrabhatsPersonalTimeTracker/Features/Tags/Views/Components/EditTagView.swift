import SwiftUI

struct EditTagView: View {
    @Binding var name: String
    @Binding var color: CatppuccinFrappe
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Tag Name", text: $name)
                CatppuccinColorPicker(selectedColor: $color)
            }
            .padding()
            .navigationTitle("Edit Tag")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
} 
