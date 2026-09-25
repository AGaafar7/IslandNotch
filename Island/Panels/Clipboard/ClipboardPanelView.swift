//
//  ClipboardPanelView.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var monitor: ClipboardMonitor
    var onSelect: (ClipboardItem) -> Void
    var onClose: () -> Void
    
    @State private var searchText = ""
    
    private var filteredItems: [ClipboardItem] {
        guard !searchText.isEmpty else { return monitor.items }
        return monitor.items.filter { matches($0, query: searchText) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.on.clipboard")
                    .foregroundStyle(.white)
                Text("Clipboard")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                // Search field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.5))
                    
                    TextField("Search", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .frame(width: 140)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                )
                
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
            
            if filteredItems.isEmpty {
                Text(searchText.isEmpty ? "Nothing copied yet" : "No matches")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            ClipboardCardView(item: item) {
                                onSelect(item)
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
    
    private func matches(_ item: ClipboardItem, query: String) -> Bool {
        switch item.content {
        case .text(let text):
            return text.localizedCaseInsensitiveContains(query)
        case .image:
            return "image".localizedCaseInsensitiveContains(query)
        }
    }
}

struct ClipboardCardView: View {
    let item: ClipboardItem
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: headerIcon)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                    Spacer()
                    Text(relativeTime)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                
                content
                
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.97))
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(isHovering ? 0.5 : 0.1), lineWidth: 1)
            )
            .scaleEffect(isHovering ? 1.03 : 1.0)
            .animation(.easeOut(duration: 0.15), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
    
    @ViewBuilder
    private var content: some View {
        switch item.content {
        case .text(let text):
            Text(text)
                .font(.caption)
                .foregroundStyle(.black)
                .lineLimit(6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .image(let image):
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
    
    private var headerIcon: String {
        switch item.content {
        case .text: return "doc.text"
        case .image: return "photo"
        }
    }
    
    private var relativeTime: String {
        let interval = Date().timeIntervalSince(item.timestamp)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        return "\(Int(interval / 3600))h"
    }
}
