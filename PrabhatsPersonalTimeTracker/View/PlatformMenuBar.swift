import SwiftUI

#if os(macOS)
import AppKit
#endif

@MainActor
class PlatformMenuBar: ObservableObject {
    private var viewModel: CalendarEventLogViewModel
    private var timer: Timer?
    
    #if os(macOS)
    private var statusItem: NSStatusItem?
    #endif
    
    init(viewModel: CalendarEventLogViewModel) {
        self.viewModel = viewModel
        
        #if os(macOS)
        // Initialize status item on the main thread
        DispatchQueue.main.async { [weak self] in
            self?.initializeStatusItem()
        }
        #endif
        
        startTimer()
    }
    
    #if os(macOS)
    private func initializeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }
        
        // Add border and styling
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor.labelColor.cgColor
        
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
    
    @objc private func openApp() {
        // Bring the app to the front
        NSApp.activate(ignoringOtherApps: true)
        
        // Make sure the app is visible
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
        
        // Ensure the app is the active application
        NSApp.setActivationPolicy(.regular)
    }
    #endif
    
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
        #if os(macOS)
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
        #endif
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
        #if os(macOS)
        statusItem = nil
        #endif
    }
} 
