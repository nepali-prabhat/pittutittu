//
//  Home.swift
//  PrabhatsPersonalTimeTracker
//
//  Created by Pravat on 21/04/2025.
//

import SwiftUI

struct Home: View {
    // Getting Window Size...
    var window = NSScreen.main?.visibleFrame ?? .zero
    @AppStorage("selectedSidebarSection") private var selectedSection: SidebarView.SidebarSection = .active
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
        } detail: {
            switch selectedSection {
            case .active:
                ActiveView().frame(minWidth:400)
            case .tags:
                TagsView().frame(minWidth:400)
            case .logs:
                LogsView().frame(minWidth:400)
            case .reports:
                ReportsView().frame(minWidth:400)
            }
        }
        .frame(
            minWidth: 550,
            maxWidth: .infinity,
            minHeight: 600,
            maxHeight: .infinity
        )
    }
}

#Preview {
    Home()
}
