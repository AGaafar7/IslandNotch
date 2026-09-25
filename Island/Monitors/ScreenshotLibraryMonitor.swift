//
//  ScreenshotLibraryMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import AppKit
import Combine

@MainActor
final class ScreenshotLibraryMonitor: ObservableObject {
    static let shared = ScreenshotLibraryMonitor()
    
    @Published private(set) var recentScreenshots: [ScreenshotEntry] = []
    
    private var accessURL: URL?
    
    private init() {}
    
    func start() {
        // Resolve the Desktop bookmark the same way ScreenshotMonitor does
        guard let data = UserDefaults.standard.data(forKey: "desktopBookmark") else {
            return
        }
        
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return
        }
        
        guard url.startAccessingSecurityScopedResource() else { return }
        accessURL = url
        
        refresh()
    }
    
    func refresh() {
        guard let folder = accessURL else { return }
        
        let files = (try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        
        let screenshots = files
            .filter { isScreenshot($0.lastPathComponent) }
            .sorted { a, b in
                let aDate = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let bDate = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return aDate > bDate
            }
            .prefix(6)
            .compactMap { url -> ScreenshotEntry? in
                let date = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date()
                guard let image = NSImage(contentsOf: url) else { return nil }
                return ScreenshotEntry(url: url, image: image, date: date)
            }
        
        recentScreenshots = Array(screenshots)
    }
    
    private func isScreenshot(_ filename: String) -> Bool {
        let lower = filename.lowercased()
        let matchesPrefix = lower.hasPrefix("screenshot ") || lower.hasPrefix("screen shot")
        let matchesExtension = lower.hasSuffix(".png") || lower.hasSuffix(".jpg")
        return matchesPrefix && matchesExtension
    }
}

struct ScreenshotEntry: Identifiable {
    let id = UUID()
    let url: URL
    let image: NSImage
    let date: Date
}
