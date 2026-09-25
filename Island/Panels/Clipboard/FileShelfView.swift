//
//  FileShelfView.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI

struct FileShelfView: View {
    @ObservedObject var manager = FileShelfManager.shared
    var onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "tray.full")
                    .foregroundStyle(.white)
                Text("File Shelf")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                
                if !manager.files.isEmpty {
                    Button("Clear") {
                        manager.clear()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.caption)
                }
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            if manager.files.isEmpty {
                Text("Drag files here")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(manager.files) { file in
                            ShelfFileCard(file: file) {
                                NSWorkspace.shared.open(file.url)
                            } onRemove: {
                                manager.remove(file)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(width: 620, height: 180)
    }
}

struct ShelfFileCard: View {
    let file: ShelfFile
    let onOpen: () -> Void
    let onRemove: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: file.icon)
                .font(.system(size: 28))
                .foregroundStyle(.blue)
                .frame(height: 32)
            
            Text(file.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.black)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Text(file.sizeString)
                .font(.system(size: 9))
                .foregroundStyle(.gray)
        }
        .padding(10)
        .frame(width: 110, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.97))
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(isHovering ? 0.5 : 0.1), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 4) {
                Button {
                    shareViaAirDrop(file.url)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(Circle().fill(Color.black.opacity(0.55)))
                }
                .buttonStyle(.plain)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(5)
        }
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .onTapGesture(perform: onOpen)
        .onDrag {
            NSItemProvider(contentsOf: file.url) ?? NSItemProvider()
        }
        .help("Click to open · Drag to share")
    }
    private func shareViaAirDrop(_ url: URL) {
        // Copy the file into the app's container so the share service can read it
        let tempDir = FileManager.default.temporaryDirectory
        let dest = tempDir.appendingPathComponent(url.lastPathComponent)
        
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: url, to: dest)
        } catch {
            print("[Shelf] Copy failed: \(error)")
            return
        }
        
        guard let service = NSSharingService(named: .sendViaAirDrop) else {
            print("[Shelf] AirDrop unavailable")
            return
        }
        
        service.perform(withItems: [dest])
    }
}
