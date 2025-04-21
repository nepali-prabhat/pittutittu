import SwiftUI
import PrabhatsPersonalTimeTracker

struct DeleteTagConfirmationView: View {
    let tag: Tag
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Delete Tag")
                    .font(.title)
                    .padding(.top)
                
                Text("Are you sure you want to delete '\(tag.name)'?")
                    .font(.body)
                
                if !tag.children.isEmpty {
                    Text("This will also delete \(tag.children.count) child tag(s).")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 20) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                    
                    Button("Delete", role: .destructive, action: onDelete)
                        .buttonStyle(.borderedProminent)
                }
                .padding(.top)
            }
            .padding()
            .frame(minWidth: 300)
        }
    }
} 