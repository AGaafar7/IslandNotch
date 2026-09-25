//
//  NotchRootView.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers
struct NotchRootView: View {
    @ObservedObject var state: NotchState
    
    var body: some View {
        Group {
            switch state.mode {
            case .notification(let notification):
                NotificationView(notification: notification)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            case .clipboard:
                ClipboardPanelView(
                    monitor: ClipboardMonitor.shared,
                    onSelect: { item in
                        ClipboardMonitor.shared.copyBack(item)
                        Task { await NotchPeekManager.shared.hide() }
                    },
                    onClose: {
                        Task { await NotchPeekManager.shared.hide() }
                    }
                )
                .transition(.opacity)
            case .camera:
                CameraPanelView(
                    onClose: {
                        Task { await NotchPeekManager.shared.hide() }
                    }
                )
                .transition(.opacity)
            case .batteryDetail:
                BatteryDetailView(onClose: {
                        Task { await NotchPeekManager.shared.hide() }
                    })
                    .transition(.opacity)
            case .fileShelf:
                FileShelfView(onClose: {
                    Task { await NotchPeekManager.shared.hide()}
                })
                .transition(.opacity)
                .onDrop(of: [.fileURL, .image], isTargeted: nil) { providers in
                    for provider in providers {
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            guard let url else { return }
                            Task { @MainActor in
                                FileShelfManager.shared.add(urls: [url])
                                NotchPeekManager.shared.showFileShelf()
                            }
                        }
                    }
                    return true
                }
            case .dashboard:
                DashboardView(onClose: {
                    Task { await NotchPeekManager.shared.hide() }
                })
                .transition(.opacity)
            case .none:
                Color.clear
                    .frame(width: 1, height: 1)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: state.mode)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }
}

struct NotificationView: View {
    let notification: NotchNotification
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(notification.message)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}
