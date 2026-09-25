//
//  DropZoneContentView.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import AppKit

final class DropZoneContentView: NSView {
    var onFilesDropped: (([URL]) -> Void)?
    
    private var isHighlighted = false
    private let label = NSTextField(labelWithString: "Drop files here")
    private let icon = NSImageView()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
        
        // Register for everything we might see
        registerForDraggedTypes([
            .fileURL,
            .URL,
            .tiff,
            .png,
            .string,
            NSPasteboard.PasteboardType("NSFilenamesPboardType"),
            NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-url")
        ])
        
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        layer?.cornerRadius = 16
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.15).cgColor
        
        icon.image = NSImage(systemSymbolName: "arrow.down.doc.fill", accessibilityDescription: nil)
        icon.contentTintColor = .white
        icon.translatesAutoresizingMaskIntoConstraints = false
        
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(icon)
        addSubview(label)
        
        NSLayoutConstraint.activate([
            icon.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            icon.widthAnchor.constraint(equalToConstant: 24),
            icon.heightAnchor.constraint(equalToConstant: 24),
            
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Drag & Drop
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        print("[DropZone] draggingEntered")
        setHighlighted(true)
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        print("[DropZone] draggingExited")
        setHighlighted(false)
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("[DropZone] prepareForDragOperation")
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("[DropZone] performDragOperation")
        let pasteboard = sender.draggingPasteboard
        
        let urls = extractURLs(from: pasteboard)
        print("[DropZone] Extracted \(urls.count) URLs")
        
        guard !urls.isEmpty else {
            print("[DropZone] No URLs found on pasteboard")
            return false
        }
        
        setHighlighted(false)
        onFilesDropped?(urls)
        return true
    }
    
    private func extractURLs(from pasteboard: NSPasteboard) -> [URL] {
        var urls: [URL] = []
        
        // 1. Try modern file URL reading
        if let fileURLs = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] {
            urls.append(contentsOf: fileURLs)
        }
        
        // 2. Try the legacy NSFilenamesPboardType (array of path strings)
        if urls.isEmpty,
           let paths = pasteboard.propertyList(
            forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")
           ) as? [String] {
            urls.append(contentsOf: paths.map { URL(fileURLWithPath: $0) })
        }
        
        // 3. Try reading individual string paths
        if urls.isEmpty, let string = pasteboard.string(forType: .string) {
            let path = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if path.hasPrefix("/") || path.hasPrefix("~") {
                let expanded = (path as NSString).expandingTildeInPath
                urls.append(URL(fileURLWithPath: expanded))
            }
        }
        
        // 4. Try URLs (for browser drags)
        if urls.isEmpty,
           let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            urls.append(contentsOf: objects)
        }
        
        return urls
    }
    
    private func setHighlighted(_ highlighted: Bool) {
        isHighlighted = highlighted
        layer?.borderColor = (highlighted
            ? NSColor.controlAccentColor
            : NSColor.white.withAlphaComponent(0.15)
        ).cgColor
        layer?.backgroundColor = (highlighted
            ? NSColor.controlAccentColor.withAlphaComponent(0.25)
            : NSColor.black.withAlphaComponent(0.85)
        ).cgColor
    }
}
