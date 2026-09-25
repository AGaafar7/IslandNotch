//
//  FileShelfManager.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI
import UniformTypeIdentifiers
import Combine

@MainActor
final class FileShelfManager: ObservableObject {
    static let shared = FileShelfManager()
    
    @Published private(set) var files: [ShelfFile] = []
    
    private let maxFiles = 20
    
    private init() {}
    
    func add(urls: [URL]) {
        for url in urls {
            // Skip duplicates
            if files.contains(where: { $0.url == url }) { continue }
            
            let file = ShelfFile(url: url, addedAt: Date())
            files.insert(file, at: 0)
        }
        
        // Enforce cap
        if files.count > maxFiles {
            files = Array(files.prefix(maxFiles))
        }
    }
    
    func remove(_ file: ShelfFile) {
        files.removeAll { $0.id == file.id }
    }
    
    func clear() {
        files.removeAll()
    }
}

struct ShelfFile: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let addedAt: Date
    
    var name: String { url.lastPathComponent }
    
    var icon: String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "pdf": return "doc.richtext"
        case "png", "jpg", "jpeg", "gif", "heic", "webp": return "photo"
        case "mp4", "mov", "avi": return "film"
        case "mp3", "wav", "aac", "m4a": return "music.note"
        case "zip", "rar", "7z": return "archivebox"
        case "txt", "md", "rtf": return "doc.text"
        case "swift", "py", "js", "ts", "cpp", "c", "h": return "chevron.left.forwardslash.chevron.right"
        default:
            if let uti = UTType(filenameExtension: ext) {
                if uti.conforms(to: .image) { return "photo" }
                if uti.conforms(to: .movie) || uti.conforms(to: .video) { return "film" }
                if uti.conforms(to: .audio) { return "music.note" }
                if uti.conforms(to: .archive) { return "archivebox" }
                if uti.conforms(to: .text) { return "doc.text" }
            }
            return "doc"
        }
    }
    
    var sizeString: String {
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}
