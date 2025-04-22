import SwiftUI

struct ImportTagsView: View {
    @Binding var text: String
    let onImport: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .font(.body.monospaced())
                    .frame(minHeight: 200)
                    .padding()
                    .border(Color.gray.opacity(0.2))
            }
            .padding()
            .navigationTitle("Import Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        text = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onImport(text)
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
} 