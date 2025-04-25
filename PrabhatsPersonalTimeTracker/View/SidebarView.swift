//
//  SidebarView.swift
//  PrabhatsPersonalTimeTracker
//
//  Created by Pravat on 21/04/2025.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection
    
    enum SidebarSection: String, CaseIterable, Identifiable {
        case active = "Active"
        case logs = "Logs"
        case reports = "Reports"
        case tags = "Tags"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .active: return "play.circle.fill"
            case .logs: return "list.bullet.rectangle.fill"
            case .reports: return "chart.bar.fill"
            case .tags: return "tag.fill"
            }
        }
    }
    
    var body: some View {
        List(selection: $selection) {
            ForEach(SidebarSection.allCases) { section in
                NavigationLink(value: section) {
                    Label(section.rawValue, systemImage: section.icon)
                }
            }
        }
        .listStyle(.sidebar)
        .background(BlurWindow())
    }
}

#Preview {
    SidebarView(selection: .constant(.active))
}
