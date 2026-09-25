//
//  ScreenshotMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 08/10/2026.
//

import Foundation
import os

final class ScreenshotMonitor {
    var onScreenshot: ((String) -> Void)?
    
    private var source: DispatchSourceFileSystemObject?
    private var folderDescriptor: Int32 = -1
    private var knownFiles: Set<String> = []
    private var hasInitialized = false
    private let debouncer = Debouncer(delay: 0.4)
    private var activeFolderURL: URL?
    private var screenshotsFolder: URL? {
        guard let data = UserDefaults.standard.data(forKey: "desktopBookmark") else {
            return nil
        }
        
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        
        // Keep this URL alive — the caller must hold it
        if !url.startAccessingSecurityScopedResource() {
            print("[ScreenshotMonitor] Failed to start security-scoped access")
            return nil
        }
        
        return url
    }
    
    func start() {
        guard let folder = screenshotsFolder else {
            print("[ScreenshotMonitor] No desktop bookmark — user must grant access")
            return
        }
        self.activeFolderURL = folder
        
        //Baseline: record existing screenshots without firing
        let existing = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        knownFiles = Set(existing.filter { isScreenshot($0) })
        hasInitialized = true
        
        folderDescriptor = open(folder.path, O_EVTONLY)
        guard folderDescriptor >= 0 else {
            Log.screenshot.error("Failed to open folder: \(folder.path, privacy: .public)")
            return
        }
        
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: folderDescriptor, eventMask: .write, queue: .main)
        source.setEventHandler { [weak self] in
            self?.scanForNewScreenshots()
        }
        
        source.setCancelHandler { [weak self] in
            guard let self else { return }
            if self.folderDescriptor >= 0 {
                close(self.folderDescriptor)
                self.folderDescriptor = -1
            }
        }
        
        source.resume()
        self.source = source
    }
    
    private func scanForNewScreenshots() {
        guard let folder = activeFolderURL else { return }
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: folder.path) else {
            return
        }
        
        let currentScreenshots = Set(files.filter { isScreenshot($0) })
        let newFiles = currentScreenshots.subtracting(knownFiles)
        knownFiles = currentScreenshots
        guard let newest = newFiles.first else { return }
        
        debouncer.call { [weak self] in
            self?.onScreenshot?(newest)
        }
    }
    
    private func isScreenshot(_ filename: String) -> Bool {
        let lower = filename.lowercased()
        let matchesPrefix = lower.hasPrefix("screenshot ") || lower.hasPrefix("screen shot")
        let matchesExtension = lower.hasSuffix(".png") || lower.hasSuffix(".jpg")
        return matchesPrefix && matchesExtension
    }
    
    func stop() {
        source?.cancel()
        source = nil
        activeFolderURL?.stopAccessingSecurityScopedResource()
        activeFolderURL = nil
    }
}
