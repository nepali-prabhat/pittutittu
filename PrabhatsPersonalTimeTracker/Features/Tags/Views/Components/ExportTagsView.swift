import SwiftUI

struct ExportTagsView: View {
    let text: String
    let onDone: () -> Void
    let onReset: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: .constant(text))
                    .font(.body.monospaced())
                    .frame(minHeight: 200)
                    .padding()
                    .border(Color.gray.opacity(0.2))
                    .onAppear {
                        print("ExportTagsView text: \(text)")
                    }
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
                ToolbarItem(placement: .primaryAction) {
                    Button("Copy to Clipboard") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button("Reset Text") {
                        onReset()
                    }
                }
            }
        }
    }
} 


#Preview {
    ExportTagsView(
        text: """
        {
          "name": "Work",
          "color": "blue",
          "children": [
            {
              "name": "Meetings",
              "color": "red",
              "children": []
            }
          ]
        }
        """,
        onDone: {},
        onReset: {}
    )
}
