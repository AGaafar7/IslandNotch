//
//  SettingsView.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    var body: some View {
        TabView {
            NotificationsSettingsView(settings: settings)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480, height: 340)
    }
}

struct NotificationsSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section("System Events") {
                Toggle("Charger connected / disconnected", isOn: $settings.notifyCharger)
                Toggle("Low battery warning", isOn: $settings.notifyLowBattery)
                Toggle("AirPods connected / disconnected", isOn: $settings.notifyAirPods)
                Toggle("Wi-Fi network changes", isOn: $settings.notifyWifi)
            }
            
            Section("Activity") {
                Toggle("Screenshot taken", isOn: $settings.notifyScreenshot)
                Toggle("Clipboard copy confirmation", isOn: $settings.notifyClipboard)
            }
        }
        .padding()
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Launch at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.launchAtLogin = $0 }
                ))
                Toggle("Show battery in compact pill", isOn: $settings.compactBattery)
                Toggle("Upcoming calendar events", isOn: $settings.notifyCalendar)
                
                HStack {
                    Text("Peek duration")
                    Spacer()
                    Slider(value: $settings.peekDuration, in: 2.0...10.0, step: 0.5)
                        .frame(width: 160)
                    Text("\(settings.peekDuration, specifier: "%.1f")s")
                        .frame(width: 40, alignment: .trailing)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Clipboard") {
                Stepper(
                    "Maximum items: \(settings.clipboardMaxItems)",
                    value: $settings.clipboardMaxItems,
                    in: 5...100,
                    step: 5
                )
            }
            Section("Usage") {
                Button("Reset usage statistics") {
                    UsageStats.shared.reset()
                }
            }
        }
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            
            Text("Island")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("A dynamic notch for your Mac")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("Version 0.1.0")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
