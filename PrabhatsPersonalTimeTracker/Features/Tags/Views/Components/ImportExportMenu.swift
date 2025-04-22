import SwiftUI

struct ImportExportMenu: View {
    @Binding var showingImportSheet: Bool
    @Binding var showingExportSheet: Bool
    @Binding var importText: String
    @Binding var exportText: String
    let onExport: () -> String
    
    var body: some View {
        Menu {
            Button(action: {
                showingImportSheet = true
            }) {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            
            Button(action: {
                exportText = onExport()
                showingExportSheet = true
            }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        } label: {
            Label("Import/Export", systemImage: "newspaper")
                .foregroundStyle(.secondary)
        }
    }
} 