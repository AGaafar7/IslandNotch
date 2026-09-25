//
//  NotchPeekManager.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import SwiftUI
import DynamicNotchKit

@MainActor
final class NotchPeekManager {
    static let shared = NotchPeekManager()
    
    private var notch: DynamicNotch<AnyView, CompactLeadingView, CompactTrailingView>?
    private var hideTask: Task<Void, Never>?
    
    private init() {
        
    }
    func configure(notch: DynamicNotch<AnyView, CompactLeadingView, CompactTrailingView>) {
        self.notch = notch
    }
    
    // Show a peek notification that expands the notch, then autohide
    func peek(
        icon: String,
        title: String,
        message: String,
        duration: TimeInterval? = nil
    ) {
        guard let notch else { return }
        UsageStats.shared.incrementPeeks()
        hideTask?.cancel()
        
        NotchState.shared.show(icon: icon, title: title, message: message)
        let actualDuration = duration ?? calculateDuration(for: message)
        
        Task {
            
            await notch.expand()
            
            hideTask = Task {
                try? await Task.sleep(for: .seconds(actualDuration))
                guard !Task.isCancelled else { return }
                NotchState.shared.clear()
                if AppSettings.shared.compactBattery {
                    try? await Task.sleep(for: .milliseconds(100))
                    await notch.compact()
                } else {
                    await notch.hide()
                }
            }
        }
    }
    
    func showDashboard() {
        guard let notch else { return }
        UsageStats.shared.incrementDashboard()
        hideTask?.cancel()
        NotchState.shared.showDashboard()
        Task { await notch.expand() }
    }
    
    private func calculateDuration(for message: String) -> TimeInterval {
        // Base 2.5s + 0.05s per character, capped at 5s
        let base: TimeInterval = 2.5
        let perChar: TimeInterval = 0.05
        let maxDuration: TimeInterval = 5.0
        return min(base + Double(message.count) * perChar, maxDuration)
    }
    
    func hide() async {
        guard let notch else { return }
        hideTask?.cancel()
        NotchState.shared.clear()
        await notch.hide()
    }
    
    func showClipboard() {
        guard let notch else { return }
        hideTask?.cancel()
        NotchState.shared.showClipboard()
        
        Task {
            await notch.expand()
            // No auto-hide — user closes manually via ✕ button
        }
    }
    
    func showFileShelf() {
        guard let notch else { return }
        hideTask?.cancel()
        NotchState.shared.showFileShelf()
        Task {
            await notch.expand()
        }
    }
    
    func showBatteryDetail() {
        guard let notch else { return }
        hideTask?.cancel()
        NotchState.shared.showBatteryDetail()
        Task {
            await notch.expand()
        }
    }
    
    func showCamera() {
        guard let notch else { return }
        hideTask?.cancel()
        NotchState.shared.showCamera()
        
        Task {
            await notch.expand()
            // No auto-hide — user closes via ✕ or Escape
        }
    }

}
