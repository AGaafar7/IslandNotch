//
//  NotchState.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import SwiftUI
import Combine

@MainActor
final class NotchState: ObservableObject {
    static let shared = NotchState()
    
    enum Mode: Equatable {
        case notification(NotchNotification)
        case clipboard
        case camera
        case batteryDetail
        case fileShelf
        case dashboard
    }
    
    @Published var mode: Mode?
    
    private init() {}
    
    func showDashboard() {
        mode = .dashboard
    }
    
    func showFileShelf() {
        mode = .fileShelf
    }
    
    func showBatteryDetail() {
        mode = .batteryDetail
    }
    
    func show(icon: String, title: String, message: String) {
        mode = .notification(NotchNotification(icon: icon, title: title, message: message))
    }
    
    func showCamera() {
        mode = .camera
    }
    
    func showClipboard() {
        mode = .clipboard
    }
    
    func clear() {
        mode = nil
    }
}

struct NotchNotification: Equatable {
    let icon: String
    let title: String
    let message: String
}
