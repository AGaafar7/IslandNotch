//
//  NotchDropHandler.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import AppKit

final class NotchDropHandler {
    static let shared = NotchDropHandler()
    
    private var dragMonitor: Any?
    private var releaseMonitor: Any?
    private var dropZone: DropZoneWindow?
    private var isDragging = false
    
    private init() {}
    
    func start() {
        dragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] _ in
            self?.handleDragEvent()
        }
        
        releaseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] _ in
            self?.handleDragRelease()
        }
    }
    
    func stop() {
        if let dragMonitor { NSEvent.removeMonitor(dragMonitor) }
        if let releaseMonitor { NSEvent.removeMonitor(releaseMonitor) }
        dragMonitor = nil
        releaseMonitor = nil
        dropZone?.orderOut(nil)
        dropZone = nil
    }
    
    private func handleDragEvent() {
        // Check for file content on the pasteboard
        let pasteboard = NSPasteboard(name: .drag)
        guard let types = pasteboard.types,
              types.contains(.fileURL) || types.contains(NSPasteboard.PasteboardType("NSFilenamesPboardType")) else {
            return
        }
        
        // Only show if the cursor is close to the notch area
        guard isCursorNearNotch() else {
            Task { @MainActor in
                // If the drop zone is showing but cursor drifted away, hide it
                if isDragging {
                    isDragging = false
                    dropZone?.fadeOut()
                }
            }
            return
        }
        
        Task { @MainActor in
            if !isDragging {
                isDragging = true
                showDropZone()
            }
        }
    }
    
    private func handleDragRelease() {
        Task { @MainActor in
            isDragging = false
            try? await Task.sleep(for: .milliseconds(150))
            dropZone?.fadeOut()
        }
    }
    
    private func isCursorNearNotch() -> Bool {
        guard let screen = NSScreen.main else { return false }
        let notchFrame = computeNotchFrame(on: screen)
        
        // Expand the notch frame by 100pt on all sides to make a comfortable hit area
        let expanded = notchFrame.insetBy(dx: -100, dy: -100)
        return expanded.contains(NSEvent.mouseLocation)
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
    
    @MainActor
    private func showDropZone() {
        if dropZone == nil {
            dropZone = DropZoneWindow()
            dropZone?.onFilesDropped = { urls in
                Task { @MainActor in
                    FileShelfManager.shared.add(urls: urls)
                    NotchPeekManager.shared.showFileShelf()
                }
            }
        }
        dropZone?.showBelowNotch()
    }
}
