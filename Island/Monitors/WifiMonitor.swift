//
//  WifiMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import SystemConfiguration
import CoreWLAN

class WifiMonitor {
    var onWifiChange: ((String?) -> Void)?
    private var previousSSID: String?
    private var store: SCDynamicStore?
    private var hasInitialized = false
    private let debouncer = Debouncer(delay: 0.8)
    
    func start() {
        let permissionManager = LocationPermissionManager.shared
        permissionManager.onAuthorized = { [weak self] in
            self?.setupDynamicStore()
        }
        permissionManager.onDenied = {
            print("[WifiMonitor] Location permission denied — SSID will be nil")
        }
        permissionManager.requestPermission()
    }
    
    private func setupDynamicStore() {
        let callback: SCDynamicStoreCallBack = { store, changedKeys, context in
            guard let context = context else { return }
            let monitor = Unmanaged<WifiMonitor>.fromOpaque(context).takeUnretainedValue()
            monitor.checkWifi()
        }
        
        var context = SCDynamicStoreContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil)
        
        guard let store = SCDynamicStoreCreate(kCFAllocatorDefault, "WiFiMonitor" as CFString, callback, &context) else {
            return
        }
        self.store = store
        
        let keys = ["State:/Network/Global/IPv4"] as CFArray
        SCDynamicStoreSetNotificationKeys(store, nil, keys)
        
        let source = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, store, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        
        checkWifi()
    }
    
    private func checkWifi() {
        let currentSSID = CWWiFiClient.shared().interface()?.ssid()
        
        if !hasInitialized {
            previousSSID = currentSSID
            hasInitialized = true
            return
        }
        
        guard currentSSID != previousSSID else { return }
        previousSSID = currentSSID
        
        let captured = currentSSID
        debouncer.call { [weak self] in
            self?.onWifiChange?(captured)
        }
    }
}
