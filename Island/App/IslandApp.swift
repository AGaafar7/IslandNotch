//
//  IslandApp.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import SwiftUI

@main
struct IslandApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Island", systemImage: "sparkles") {
            SettingsLink {
                Text("Settings…")
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Button("Clipboard History") {
                Task { @MainActor in
                    NotchPeekManager.shared.showClipboard()
                }
            }
            
            Button("Camera Mirror") {
                Task { @MainActor in
                    NotchPeekManager.shared.showCamera()
                }
            }
            
            Button("Dashboard") {
                Task { @MainActor in
                    NotchPeekManager.shared.showDashboard()
                }
            }
            
            Menu("Start Timer") {
                Button("5 minutes") {
                    CompactState.shared.startTimer(seconds: 5 * 60)
                }
                Button("15 minutes") {
                    CompactState.shared.startTimer(seconds: 15 * 60)
                }
                Button("25 minutes") {
                    CompactState.shared.startTimer(seconds: 25 * 60)
                }
                Button("45 minutes") {
                    CompactState.shared.startTimer(seconds: 45 * 60)
                }
                Divider()
                Button("Cancel Timer") {
                    CompactState.shared.cancelTimer()
                }
            }
            
            Divider()
            
            Button("Quit Island") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)
        
        Settings {
            SettingsView()
        }
    }
}
