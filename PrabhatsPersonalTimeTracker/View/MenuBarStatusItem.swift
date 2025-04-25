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
        
        // Add border and styling
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor.labelColor.cgColor
        
        // Add space after the title
        button.title = button.title
        
        let menu = NSMenu()
        
        // Add menu items
        let activeSessionsItem = NSMenuItem(title: "Active Sessions", action: nil, keyEquivalent: "")
        activeSessionsItem.isEnabled = false
        menu.addItem(activeSessionsItem)
        menu.addItem(NSMenuItem.separator())
        
        // Add active sessions
        let activeLogs = viewModel.logs.filter { $0.timerEndDate == nil }
        if activeLogs.isEmpty {
            let noActiveItem = NSMenuItem(title: "No active sessions", action: nil, keyEquivalent: "")
            noActiveItem.isEnabled = false
            menu.addItem(noActiveItem)
        } else {
            for log in activeLogs {
                let item = NSMenuItem(
                    title: "\(log.title) (\(formatDuration(from: log.startDate, to: Date())))",
                    action: #selector(openApp),
                    keyEquivalent: ""
                )
                item.target = self
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Add New Event item
        let newEventItem = NSMenuItem(
            title: "New Event",
            action: #selector(openNewEvent),
            keyEquivalent: "n"
        )
        newEventItem.target = self
        menu.addItem(newEventItem)
        
        // Add Open App item
        let openAppItem = NSMenuItem(
            title: "Open App",
            action: #selector(openApp),
            keyEquivalent: "o"
        )
        openAppItem.target = self
        menu.addItem(openAppItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add Quit item
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
        
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
        
        if !activeLogs.isEmpty {
            let durations = activeLogs.map { log in
                formatDuration(from: log.startDate, to: Date())
            }
            button.title = durations.joined(separator: " | ")
        } else {
            button.title = ""
        }
        
        // Update menu items
        setupStatusItem()
    }
    
    @objc private func openApp() {
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func openNewEvent() {
        NSApp.activate(ignoringOtherApps: true)
        // Post a notification to open the new event view
        NotificationCenter.default.post(name: NSNotification.Name("OpenNewEvent"), object: nil)
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