//
//  ClipboardMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import Combine
import AppKit

enum ClipboardContent: Equatable {
    case text(String)
    case image(NSImage)
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: ClipboardContent
    let timestamp: Date
}

final class ClipboardMonitor: ObservableObject {
    static let shared = ClipboardMonitor()
    
    @Published private(set) var items: [ClipboardItem] = []
    
    var onNewItem: ((ClipboardItem) -> Void)?
    
    private let maxItems = 30
    private let thumbnailSize = CGSize(width: 400, height: 400)
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    
    private init() {}
    
    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }
    
    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        
        // Priority 1: image
        if let image = readImage(from: pasteboard) {
            let thumbnail = downscale(image, to: thumbnailSize)
            let item = ClipboardItem(content: .image(thumbnail), timestamp: Date())
            
            if case .image(let existing) = items.first?.content,
               existing.tiffRepresentation == thumbnail.tiffRepresentation {
                return
            }
            
            insert(item)
            return
        }
        
        // Priority 2: text
        if let text = pasteboard.string(forType: .string),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if case .text(let existing) = items.first?.content, existing == text {
                return
            }
            
            let item = ClipboardItem(content: .text(text), timestamp: Date())
            insert(item)
        }
    }
    
    private func readImage(from pasteboard: NSPasteboard) -> NSImage? {
        // Try common image types
        let types: [NSPasteboard.PasteboardType] = [.tiff, .png]
        for type in types {
            if let data = pasteboard.data(forType: type),
               let image = NSImage(data: data) {
                return image
            }
        }
        return nil
    }
    
    private func downscale(_ image: NSImage, to size: CGSize) -> NSImage {
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return image }
        
        let widthRatio = size.width / originalSize.width
        let heightRatio = size.height / originalSize.height
        let ratio = min(widthRatio, heightRatio, 1.0)  // never upscale
        
        let newSize = CGSize(
            width: originalSize.width * ratio,
            height: originalSize.height * ratio
        )
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func insert(_ item: ClipboardItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        UsageStats.shared.incrementClipboard()
        onNewItem?(item)
    }
    
    func copyBack(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let image):
            if let tiff = image.tiffRepresentation {
                pasteboard.setData(tiff, forType: .tiff)
            }
        }
        
        lastChangeCount = pasteboard.changeCount
    }
    
    func clear() {
        items.removeAll()
    }
}
