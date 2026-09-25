//
//  AppDelegate.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import AppKit
import SwiftUI
import DynamicNotchKit
import CoreLocation
import os

class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    var notch: DynamicNotch<AnyView, CompactLeadingView, CompactTrailingView>?
    let powerMonitor = PowerSourceMonitor.shared
    let audioMonitor = AudioRouteMonitor()
    let wifiMonitor = WifiMonitor()
    let screenshotMonitor = ScreenshotMonitor()
    let clipboardMonitor = ClipboardMonitor.shared
    let calendarMonitor = CalendarMonitor.shared
    let microphoneMonitor = MicrophoneMonitor()
    let volumeMonitor = VolumeMonitor()



    private var welcomeWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let hasSeenWelcome = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        if !hasSeenWelcome {
            showWelcomeWindow()
        } else {
            performFullSetup()
        }
    }
    
    // MARK: - Welcome
    
    private func showWelcomeWindow() {
        let view = WelcomeView { [weak self] in
            guard let self else { return }
            UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
            self.welcomeWindow?.close()
            self.welcomeWindow = nil
            self.performFullSetup()
        }
        
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to Island"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        self.welcomeWindow = window
    }
    
    // MARK: - Full Setup
    
    private func performFullSetup() {
        LocationPermissionManager.shared.requestPermission()
        
        let rootView = AnyView(NotchRootView(state: NotchState.shared))
        let notch = DynamicNotch {
            rootView
        } compactLeading: {
            CompactLeadingView()
        } compactTrailing: {
            CompactTrailingView()
        }
        
        self.notch = notch
        NotchPeekManager.shared.configure(notch: notch)
        NotchDropHandler.shared.start()
        NotchHoverMonitor.shared.start()
        PagingGestureMonitor.shared.start()
        WeatherMonitor.shared.start()
        
        
        // MARK: Focus Timer
        CompactState.shared.onTimerFinished = {
            Task { @MainActor in
                NSSound(named: "Glass")?.play()
                NotchPeekManager.shared.peek(
                    icon: "timer",
                    title: "Timer Complete",
                    message: "Time's up"
                )
            }
        }
                
        // MARK: Microphone
        microphoneMonitor.onMicStateChange = { isActive in
            Task { @MainActor in
                CompactState.shared.setMicActive(isActive)
            }
        }
        microphoneMonitor.start()
        
        // MARK: Volume
        volumeMonitor.onVolumeChange = { volume in
            Task { @MainActor in
                let percent = Int(volume * 100)
                let icon = volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill"
                NotchPeekManager.shared.peek(
                    icon: icon,
                    title: "Volume",
                    message: "\(percent)%"
                )
            }
        }
        volumeMonitor.start()
        
        // MARK: Charger
        powerMonitor.onPowerChange = { state in
            guard AppSettings.shared.notifyCharger else { return }
            Task { @MainActor in
                NotchPeekManager.shared.peek(
                    icon: state.isPluggedIn ? "powerplug.fill" : "battery.100",
                    title: state.isPluggedIn ? "Charger Connected" : "Charger Disconnected",
                    message: state.isPluggedIn
                        ? "Now charging - \(state.batteryPercentage)%"
                        : "Running on battery - \(state.batteryPercentage)%"
                )
            }
        }
        
        
        
        // MARK: Low Battery
        powerMonitor.onLowBattery = { percentage in
            guard AppSettings.shared.notifyLowBattery else { return }
            Task { @MainActor in
                NotchPeekManager.shared.peek(
                    icon: "battery.25",
                    title: "Low Battery",
                    message: "\(percentage)% remaining"
                )
            }
        }
        powerMonitor.start()
        
        // MARK: Audio (AirPods)
        audioMonitor.onRouteEvent = { event in
            Task { @MainActor in
                switch event {
                case .airPodsConnected:
                    CompactState.shared.setAirPods(connected: true)
                case .airPodsDisconnected, .otherDeviceChanged:
                    CompactState.shared.setAirPods(connected: false)
                }
            }
            
            guard AppSettings.shared.notifyAirPods else { return }
            
            Task { @MainActor in
                switch event {
                case .airPodsConnected(let name):
                    NotchPeekManager.shared.peek(
                        icon: "airpods",
                        title: "AirPods Connected",
                        message: name
                    )
                case .airPodsDisconnected(let name):
                    NotchPeekManager.shared.peek(
                        icon: "airpods",
                        title: "AirPods Disconnected",
                        message: name
                    )
                case .otherDeviceChanged:
                    break
                }
            }
        }
        audioMonitor.start()
        
        // MARK: Wi-Fi
        wifiMonitor.onWifiChange = { ssid in
            
            Task { @MainActor in
                CompactState.shared.setSSID(ssid)
            }
            
            guard AppSettings.shared.notifyWifi else { return }
            
            Task { @MainActor in
                NotchPeekManager.shared.peek(
                    icon: ssid != nil ? "wifi" : "wifi.slash",
                    title: ssid != nil ? "Wi-Fi Connected" : "Wi-Fi Disconnected",
                    message: ssid ?? "No network"
                )
            }
        }
        wifiMonitor.start()
        
        // MARK: Screenshot
        screenshotMonitor.onScreenshot = { filename in
            guard AppSettings.shared.notifyScreenshot else { return }
            Task { @MainActor in
                let displayName = (filename as NSString).deletingPathExtension
                NotchPeekManager.shared.peek(
                    icon: "camera.viewfinder",
                    title: "Screenshot",
                    message: displayName
                )
            }
        }
        requestDesktopAccess()
        screenshotMonitor.start()
        ScreenshotLibraryMonitor.shared.start()
        
        // MARK: Clipboard
        clipboardMonitor.onNewItem = { [weak self] item in
            guard AppSettings.shared.notifyClipboard else { return }
            Task { @MainActor in
                guard let self else { return }
                let (icon, title, message) = self.describe(item)
                NotchPeekManager.shared.peek(icon: icon, title: title, message: message)
            }
        }
        clipboardMonitor.start()
        
        // MARK: Calendar
        calendarMonitor.onUpcomingEvent = { event in
            guard AppSettings.shared.notifyCalendar else { return }
            Task { @MainActor in
                NotchPeekManager.shared.peek(
                    icon: "calendar",
                    title: event.title,
                    message: event.minutesUntil == 0
                        ? "Starting now"
                        : "Starts in \(event.minutesUntil) min"
                )
            }
        }
        calendarMonitor.start()
    }
    
    // MARK: - Desktop Access
    private func describe(_ item: ClipboardItem) -> (String, String, String) {
        switch item.content {
        case .text(let text):
            let preview = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(40)
            return ("doc.on.clipboard", "Copied", String(preview))
        case .image:
            return ("photo", "Copied image", "Image from clipboard")
        }
    }
    
    private func requestDesktopAccess() {
        let key = "hasDesktopAccess"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        
        let panel = NSOpenPanel()
        panel.message = "Island needs access to your Desktop to detect screenshots."
        panel.prompt = "Grant Access"
        panel.directoryURL = URL(fileURLWithPath: "/Users/\(NSUserName())/Desktop")
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        
        guard panel.runModal() == .OK, let url = panel.url else { return }
        
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            UserDefaults.standard.set(bookmark, forKey: "desktopBookmark")
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            Log.app.error("Failed to create bookmark: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Menu Actions
    
    @objc private func openClipboardFromMenu() {
        Task { @MainActor in
            NotchPeekManager.shared.showClipboard()
        }
    }
    
    @objc func hideNotchFromMenu() {
        Task { @MainActor in
            await NotchPeekManager.shared.hide()
        }
    }
}
