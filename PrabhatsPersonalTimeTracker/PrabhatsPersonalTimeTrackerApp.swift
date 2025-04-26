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
    @StateObject private var menuBar: PlatformMenuBar
    
    init() {
        let menuBar = PlatformMenuBar(viewModel: CalendarEventLogViewModel.shared)
        _menuBar = StateObject(wrappedValue: menuBar)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        #if os(macOS)
        .windowStyle(TitleBarWindowStyle())
        #endif
    }
}
