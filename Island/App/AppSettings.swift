//
//  AppSettings.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI
import Combine
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("notifications.charger") var notifyCharger: Bool = true
    @AppStorage("notifications.lowBattery") var notifyLowBattery: Bool = true
    @AppStorage("notifications.airPods")     var notifyAirPods: Bool = true
    @AppStorage("notifications.wifi")        var notifyWifi: Bool = true
    @AppStorage("notifications.screenshot")  var notifyScreenshot: Bool = true
    @AppStorage("notifications.clipboard")   var notifyClipboard: Bool = true
    
    @AppStorage("clipboard.maxItems")        var clipboardMaxItems: Int = 30
    @AppStorage("general.peekDuration")      var peekDuration: Double = 3.0
    @AppStorage("general.compactBattery") var compactBattery: Bool = true
    @AppStorage("notifications.calendar") var notifyCalendar: Bool = true
    
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                objectWillChange.send()
            } catch {
                print("[Settings] Launch at login error: \(error)")
            }
        }
    }
    private init() {}
}

