//
//  NotchHoverMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import AppKit

final class NotchHoverMonitor {
    static let shared = NotchHoverMonitor()
    
    private var monitor: Any?
    private var openTask: Task<Void, Never>?
    private var isInside = false
    private var cachedNotchFrame: NSRect?
    private var screenObserver: Any?
    private var lastCheck: Date = .distantPast
    private let checkInterval: TimeInterval = 0.05
    
    private init() {}
    
    func start() {
        rebuildCache()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildCache()
        }
        

        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handleMouseMove()
        }
    }
    
    private func rebuildCache() {
        guard let screen = NSScreen.main else { return }
        cachedNotchFrame = computeNotchFrame(on: screen)
    }

    
    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        openTask?.cancel()
        openTask = nil
    }
    
    private func handleMouseMove() {
        let now = Date()
        guard now.timeIntervalSince(lastCheck) >= checkInterval else { return }
        lastCheck = now
        let mouseLocation = NSEvent.mouseLocation
        let inside = isCursorInNotchArea(mouseLocation)
            
        
        if inside && !isInside {
            isInside = true
            scheduleOpen()
        } else if !inside && isInside {
            isInside = false
            cancelOpen()
            scheduleClose()

        }
    }
    
    private func scheduleClose() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            guard !isInside else { return }
            // Only close if we opened it via hover
            if NotchState.shared.mode == .dashboard {
                await NotchPeekManager.shared.hide()
            }
        }
    }
    
    private func isCursorInNotchArea(_ point: NSPoint) -> Bool {
        guard let notchFrame = cachedNotchFrame else { return false }
        guard let screen = NSScreen.main else { return false }
        
        let dashboardOpen = NotchState.shared.mode == .dashboard
        
        let expanded: NSRect
        if dashboardOpen {
            let panelWidth: CGFloat = 760
            let panelHeight: CGFloat = 200
            expanded = NSRect(
                x: screen.frame.midX - panelWidth / 2,
                y: notchFrame.maxY - panelHeight,
                width: panelWidth,
                height: panelHeight
            )
        } else {
            expanded = NSRect(
                x: notchFrame.minX - 40,
                y: notchFrame.minY - 20,
                width: notchFrame.width + 80,
                height: notchFrame.height + 20
            )
        }
        
        return expanded.contains(point)
    }
    
    private func computeNotchFrame(on screen: NSScreen) -> NSRect {
        if let topLeft = screen.auxiliaryTopLeftArea,
           let topRight = screen.auxiliaryTopRightArea {
            let notchWidth = screen.frame.width - topLeft.width - topRight.width
            let notchHeight = screen.safeAreaInsets.top
            return NSRect(
                x: screen.frame.midX - notchWidth / 2,
                y: screen.frame.maxY - notchHeight,
                width: notchWidth,
                height: notchHeight
            )
        }
        
        let height = screen.frame.maxY - screen.visibleFrame.maxY
        return NSRect(
            x: screen.frame.midX - 150,
            y: screen.frame.maxY - height,
            width: 300,
            height: height
        )
    }
    
    private func scheduleOpen() {
        openTask?.cancel()
        openTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            NotchPeekManager.shared.showDashboard()
        }
    }
    
    private func cancelOpen() {
        openTask?.cancel()
        openTask = nil
    }
}
