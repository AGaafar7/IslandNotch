//
//  DropZoneWindow.swift.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import AppKit

final class DropZoneWindow: NSPanel {
    var onFilesDropped: (([URL]) -> Void)?
    
    private var dropHandlerView: DropZoneContentView!
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 70),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.level = .screenSaver
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.ignoresMouseEvents = false
        self.isMovableByWindowBackground = false
        self.isFloatingPanel = false
        
        dropHandlerView = DropZoneContentView(frame: NSRect(x: 0, y: 0, width: 300, height: 70))
        dropHandlerView.autoresizingMask = [.width, .height]
        dropHandlerView.onFilesDropped = { [weak self] urls in
            print("[DropZone] onFilesDropped fired with \(urls.count) URLs")
            self?.onFilesDropped?(urls)
            self?.fadeOut()
        }
        self.contentView = dropHandlerView
    }
    
    // Required for the window to accept mouse and drag events
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    
    func showBelowNotch() {
        guard let screen = NSScreen.main else { return }
        let notchFrame = computeNotchFrame(on: screen)
        
        let width: CGFloat = 300
        let height: CGFloat = 70
        let x = screen.frame.midX - width / 2
        let y = notchFrame.minY - height - 8
        
        let newFrame = NSRect(x: x, y: y, width: width, height: height)
        self.setFrame(newFrame, display: true)
        dropHandlerView.frame = NSRect(origin: .zero, size: newFrame.size)
        
        self.alphaValue = 0
        self.orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 1
        }
    }
    
    func fadeOut() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.animator().alphaValue = 0
        } completionHandler: {
            self.orderOut(nil)
        }
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
}
