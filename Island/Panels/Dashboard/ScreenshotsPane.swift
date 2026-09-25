//
//  ScreenshotsPane.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import SwiftUI

struct ScreenshotsPane: View {
    @ObservedObject private var library = ScreenshotLibraryMonitor.shared
    
    var body: some View {
        Group {
            if library.recentScreenshots.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.3))
                    Text("No recent screenshots")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(library.recentScreenshots) { entry in
                            ScreenshotThumb(entry: entry)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            library.start()
            library.refresh()
        }
    }
}

private struct ScreenshotThumb: View {
    let entry: ScreenshotEntry
    @State private var isHovering = false
    
    var body: some View {
        Button {
            NSWorkspace.shared.open(entry.url)
        } label: {
            VStack(spacing: 4) {
                Image(nsImage: entry.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 110, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(isHovering ? 0.5 : 0.15), lineWidth: 1)
                    )
                
                Text(relativeTime(entry.date))
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .help(entry.url.lastPathComponent)
    }
    
    private func relativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}
