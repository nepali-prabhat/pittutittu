//
//  PrabhatsPersonalTimeTrackerApp.swift
//  PrabhatsPersonalTimeTracker
//
//  Created by Pravat on 21/04/2025.
//

import SwiftUI

@main
struct PrabhatsPersonalTimeTrackerApp: App {
    @StateObject private var viewModel = CalendarEventLogViewModel.shared
    private let menuBarStatusItem: MenuBarStatusItem
    
    init() {
        menuBarStatusItem = MenuBarStatusItem(viewModel: CalendarEventLogViewModel.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        .windowStyle(TitleBarWindowStyle())
        // .windowStyle(HiddenTitleBarWindowStyle())
    }
}
