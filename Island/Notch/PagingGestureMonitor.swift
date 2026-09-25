//
//  PagingGestureMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 14/10/2026.
//

import AppKit

final class PagingGestureMonitor {
    static let shared = PagingGestureMonitor()
    
    private var dragStart: NSPoint?
    private var isActive = false
    
    private init() {}
    
    private var localMouseDown: Any?
    private var localMouseDragged: Any?
    private var localMouseUp: Any?
    private var globalMonitor: Any?

    func start() {
        print("[Paging] Monitor started")
        
        // Local: receives events on our app's windows (including the notch panel)
        localMouseDown = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.handleMouseDown(event)
            return event
        }
        localMouseDragged = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            self?.handleMouseDragged(event)
            return event
        }
        localMouseUp = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            self?.handleMouseUp(event)
            return event
        }
        
        // Global: keeps your existing drag detection for the drop zone working
        // (NotchDropHandler already has its own global monitor, so you may not
        //  need anything here at all for paging)
    }
    // MARK: - Coordinate handling
    //
    // NSEvent.mouseLocation already returns coordinates in the same
    // bottom-left origin system that NSScreen.frame uses. Do NOT flip it.
    private func mouseLocation() -> NSPoint {
        return NSEvent.mouseLocation
    }
    
    private func handleMouseDown(_ event: NSEvent) {
        let location = mouseLocation()
        let inside = isInDashboardArea(location)
        print("[Paging] mouseDown at \(location), inside: \(inside)")
        guard inside else { return }
        dragStart = location
        isActive = true
    }
    
    private func handleMouseDragged(_ event: NSEvent) {
        print("[Paging] dragged, isActive: \(isActive), dragStart: \(dragStart != nil)")
        guard isActive, let start = dragStart else { return }
        let current = mouseLocation()
        let dx = current.x - start.x
        print("[Paging] changed dx: \(dx)")
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .pagingDragChanged,
                object: nil,
                userInfo: ["dx": dx]
            )
        }
    }
    private func handleMouseUp(_ event: NSEvent) {
        guard isActive, let start = dragStart else { return }
        let current = mouseLocation()
        let dx = current.x - start.x
        isActive = false
        dragStart = nil
        print("[Paging] ended dx: \(dx)")
        Task { @MainActor in
            NotificationCenter.default.post(
                name: .pagingDragEnded,
                object: nil,
                userInfo: ["dx": dx]
            )
        }
    }
    
    // MARK: - Hit testing
    //
    // The dashboard panel appears directly below the notch.
    // The notch is at the top of the screen (in bottom-origin coords,
    // that's a Y value near screen.frame.maxY).
    private func isInDashboardArea(_ point: NSPoint) -> Bool {
        guard let screen = NSScreen.main else { return false }
        let notchFrame = computeNotchFrame(on: screen)
        
        let panelWidth: CGFloat = 720
        let panelHeight: CGFloat = 160
        
        // The panel hangs BELOW the notch, so its top edge is the notch's
        // bottom edge (notchFrame.minY), and it extends downward by panelHeight.
        let panel = NSRect(
            x: screen.frame.midX - panelWidth / 2,
            y: notchFrame.minY - panelHeight,
            width: panelWidth,
            height: panelHeight
        )
        
        print("[Paging] point: \(point)")
        print("[Paging] notchFrame: \(notchFrame)")
        print("[Paging] panel rect: \(panel)")
        print("[Paging] screen frame: \(screen.frame)")
        
        return panel.contains(point)
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
        // No notch — fall back to menu bar height
        let height = screen.frame.maxY - screen.visibleFrame.maxY
        return NSRect(
            x: screen.frame.midX - 150,
            y: screen.frame.maxY - height,
            width: 300,
            height: height
        )
    }
}

extension Notification.Name {
    static let pagingDragChanged = Notification.Name("pagingDragChanged")
    static let pagingDragEnded = Notification.Name("pagingDragEnded")
}
