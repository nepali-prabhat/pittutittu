import SwiftUI
import AppKit

@MainActor
class MenuBarStatusItem: NSObject {
    private var statusItem: NSStatusItem?
    private var viewModel: CalendarEventLogViewModel
    private var timer: Timer?
    
    init(viewModel: CalendarEventLogViewModel) {
        self.viewModel = viewModel
        super.init()
        
        // Initialize status item on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.initializeStatusItem()
        }
    }
    
    private func initializeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusItem()
        startTimer()
    }
    
    private func setupStatusItem() {
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "Time Tracker")
        button.imagePosition = .imageLeft
        button.title = "Time Tracker"
        
        let menu = NSMenu()
        
        // Add menu items
        menu.addItem(NSMenuItem(title: "Active Sessions", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Add active sessions
        for log in viewModel.logs.filter({ $0.timerEndDate == nil }) {
            let item = NSMenuItem(
                title: "\(log.title) (\(formatDuration(from: log.startDate, to: Date())))",
                action: #selector(openApp),
                keyEquivalent: ""
            )
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    private func startTimer() {
        // Invalidate existing timer if any
        timer?.invalidate()
        
        // Create new timer on main thread
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusItem()
            }
        }
        
        // Ensure timer runs on main thread
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func updateStatusItem() {
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        let activeLogs = viewModel.logs.filter { $0.timerEndDate == nil }
        
        if let activeLog = activeLogs.first {
            button.title = "\(activeLog.title) (\(formatDuration(from: activeLog.startDate, to: Date())))"
        } else {
            button.title = "Time Tracker"
        }
        
        // Update menu items
        setupStatusItem()
    }
    
    @objc private func openApp() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func formatDuration(from startDate: Date, to endDate: Date) -> String {
        let duration = endDate.timeIntervalSince(startDate)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    deinit {
        timer?.invalidate()
        statusItem = nil
    }
} 