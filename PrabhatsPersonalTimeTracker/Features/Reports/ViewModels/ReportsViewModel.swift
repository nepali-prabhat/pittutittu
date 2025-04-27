import Foundation
import CoreData
import SwiftUI

@MainActor
class ReportsViewModel: ObservableObject {
    @Published var selectedFilters: Set<TagFilter> = []
    @Published var timeRange: ClosedRange<Date> = Calendar.current.date(byAdding: .month, value: -1, to: Date())!...Date()
    @Published var reportData: [ReportDataPoint] = []
    
    private let context = CoreDataManager.shared.viewContext
    
    struct ReportDataPoint: Identifiable {
        let id = UUID()
        let tagPath: String
        let duration: TimeInterval
        let children: [ReportDataPoint]
    }
    
    func loadReportData() {
        let fetchRequest: NSFetchRequest<CalendarEventLogEntity> = CalendarEventLogEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "startDate >= %@ AND endDate <= %@", timeRange.lowerBound as NSDate, timeRange.upperBound as NSDate)
        
        do {
            let logs = try context.fetch(fetchRequest)
            var dataPoints: [String: ReportDataPoint] = [:]
            
            for log in logs {
                guard let tagPath = log.tagPath else { continue }
                
                // Apply filters
                if !selectedFilters.isEmpty {
                    let matches = selectedFilters.contains { filter in
                        filter.matches(tagPath)
                    }
                    if !matches { continue }
                }
                
                let duration = log.endDate?.timeIntervalSince(log.startDate ?? Date()) ?? 0
                
                // Split the tag path into components
                let components = tagPath.components(separatedBy: " > ")
                
                // Build the hierarchy
                var currentPath = ""
                for (index, component) in components.enumerated() {
                    if index > 0 {
                        currentPath += " > "
                    }
                    currentPath += component
                    
                    if let existing = dataPoints[currentPath] {
                        // Update existing data point
                        dataPoints[currentPath] = ReportDataPoint(
                            tagPath: currentPath,
                            duration: existing.duration + duration,
                            children: existing.children
                        )
                    } else {
                        // Create new data point
                        dataPoints[currentPath] = ReportDataPoint(
                            tagPath: currentPath,
                            duration: duration,
                            children: []
                        )
                    }
                }
            }
            
            // Build the hierarchy
            var rootDataPoints: [ReportDataPoint] = []
            for (path, dataPoint) in dataPoints {
                let components = path.components(separatedBy: " > ")
                if components.count == 1 {
                    // This is a root tag
                    rootDataPoints.append(dataPoint)
                } else {
                    // This is a child tag
                    let parentPath = components.dropLast().joined(separator: " > ")
                    if var parent = dataPoints[parentPath] {
                        var children = parent.children
                        children.append(dataPoint)
                        dataPoints[parentPath] = ReportDataPoint(
                            tagPath: parentPath,
                            duration: parent.duration,
                            children: children
                        )
                    }
                }
            }
            
            reportData = rootDataPoints
        } catch {
            print("Error loading report data: \(error)")
        }
    }
    
    func addFilter(_ filter: TagFilter) {
        selectedFilters.insert(filter)
        loadReportData()
    }
    
    func removeFilter(_ filter: TagFilter) {
        selectedFilters.remove(filter)
        loadReportData()
    }
    
    func updateTimeRange(_ range: ClosedRange<Date>) {
        timeRange = range
        loadReportData()
    }
} 