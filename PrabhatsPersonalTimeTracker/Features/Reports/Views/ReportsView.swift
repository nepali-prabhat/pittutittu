import SwiftUI
import Charts

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @State private var showingFilterSheet = false
    @State private var newFilterText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                // Time range picker
                DateRangePicker(range: $viewModel.timeRange)
                    .padding()
                
                // Active filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(viewModel.selectedFilters)) { filter in
                            FilterChip(filter: filter) {
                                viewModel.removeFilter(filter)
                            }
                        }
                        
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Label("Add Filter", systemImage: "plus")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Report visualization
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(viewModel.reportData) { dataPoint in
                            TagReportCard(dataPoint: dataPoint)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Reports")
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheet(
                    filterText: $newFilterText,
                    onAdd: {
                        let filter = TagFilter(fromPattern: newFilterText)
                        viewModel.addFilter(filter)
                        newFilterText = ""
                        showingFilterSheet = false
                    }
                )
            }
        }
    }
}

struct DateRangePicker: View {
    @Binding var range: ClosedRange<Date>
    
    var body: some View {
        HStack {
            DatePicker("From", selection: Binding(
                get: { range.lowerBound },
                set: { range = $0...range.upperBound }
            ), displayedComponents: .date)
            
            DatePicker("To", selection: Binding(
                get: { range.upperBound },
                set: { range = range.lowerBound...$0 }
            ), displayedComponents: .date)
        }
    }
}

struct FilterChip: View {
    let filter: TagFilter
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(filter.path.joined(separator: " > "))
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
    }
}

struct FilterSheet: View {
    @Binding var filterText: String
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Enter filter (e.g., foo > bar > baz or foo > (bar|bat))", text: $filterText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Text("Examples:")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading) {
                    Text("• foo > bar > baz")
                    Text("• foo > (bar|bat)")
                }
                .foregroundColor(.secondary)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Add Filter")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                    }
                    .disabled(filterText.isEmpty)
                }
            }
        }
    }
}

struct TagReportCard: View {
    let dataPoint: ReportsViewModel.ReportDataPoint
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dataPoint.tagPath)
                .font(.headline)
            
            Text(formatDuration(dataPoint.duration))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !dataPoint.children.isEmpty {
                Chart {
                    ForEach(dataPoint.children) { child in
                        BarMark(
                            x: .value("Duration", child.duration / 3600), // Convert to hours
                            y: .value("Tag", child.tagPath.components(separatedBy: " > ").last ?? "")
                        )
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
}

#Preview {
    ReportsView()
} 