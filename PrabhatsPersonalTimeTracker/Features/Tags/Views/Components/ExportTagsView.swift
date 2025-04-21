import SwiftUI

struct ExportTagsView: View {
    let text: String
    let onDone: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: .constant(text))
                    .font(.body.monospaced())
                    .frame(minHeight: 200)
                    .padding()
                    .border(Color.gray.opacity(0.2))
                    .disabled(true)
                
                Button("Copy to Clipboard") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .navigationTitle("Export Tags")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDone()
                        dismiss()
                    }
                }
            }
        }
    }
} 