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
                
                Button("Import") {
                    onImport(text)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.isEmpty)
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
            }
        }
    }
} 