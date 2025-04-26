import SwiftUI

// This file is kept for backward compatibility
// The new implementation is in PlatformMenuBar.swift
@available(*, deprecated, message: "Use PlatformMenuBar instead")
class MenuBarStatusItem: PlatformMenuBar {
    override init(viewModel: CalendarEventLogViewModel) {
        super.init(viewModel: viewModel)
    }
} 
