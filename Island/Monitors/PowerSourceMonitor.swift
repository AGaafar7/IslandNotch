//
//  PowerSourceMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import IOKit.ps
import Foundation
import Combine

struct PowerState {
    let isPluggedIn: Bool
    let batteryPercentage: Int
}
final class PowerSourceMonitor: ObservableObject {
    static let shared = PowerSourceMonitor()
    var onPowerChange: ((PowerState) -> Void)?
    var onLowBattery: ((Int) -> Void)?
    
    private var runLoopSource: CFRunLoopSource?
    private var previousState: PowerState?
    private let debouncer = Debouncer(delay: 0.8)
    private var hasWarnedLowBattery = false
    private let lowBatteryThreshold = 20
    @Published var isPluggedIn: Bool = false
    @Published var batteryPercentage: Int = 100
    @Published var cycleCount: Int = 0
    @Published var batteryHealth: Int = 0
    @Published var condition: String = "Normal"
    @Published var timeRemaining: Int = 0
    @Published var isCharging: Bool = false
    
    func start() {
        let callback: IOPowerSourceCallbackType = { context in
            guard let context else { return }
            let monitor = Unmanaged<PowerSourceMonitor>
                .fromOpaque(context)
                .takeUnretainedValue()
            monitor.checkPowerState()
        }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        guard let source = IOPSNotificationCreateRunLoopSource(callback, context)?.takeRetainedValue() else {
            return
        }
        
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
                self?.checkPowerState()
            self?.readBatteryHealth()
            }
        checkPowerState()
        readBatteryHealth()
    }
    private func checkPowerState() {
        guard let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let desc = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
              let state = desc[kIOPSPowerSourceStateKey] as? String else {
            return
        }
        
        let pluggedIn = (state == kIOPSACPowerValue)
        let currentCapacity = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let maxCapacity = desc[kIOPSMaxCapacityKey] as? Int ?? 100
        let percentage = maxCapacity > 0 ? (currentCapacity * 100) / maxCapacity: 0
        let newState = PowerState(isPluggedIn: pluggedIn, batteryPercentage: percentage)
        isPluggedIn = pluggedIn
        batteryPercentage = percentage
        
        if let timeToEmpty = desc[kIOPSTimeToEmptyKey] as? Int {
            timeRemaining = timeToEmpty  // minutes
        }
        if let timeToFull = desc[kIOPSTimeToFullChargeKey] as? Int, timeToFull > 0 {
            timeRemaining = timeToFull
        }
        isCharging = (desc[kIOPSIsChargingKey] as? Bool) ?? false
        
        if let previous = previousState, previous.isPluggedIn != pluggedIn {
            previousState = newState
            debouncer.call {
                [weak self] in self?.onPowerChange?(newState)
            }
        } else {
            previousState = newState
        }
        checkLowBattery(percentage: percentage, isPluggedIn: pluggedIn)
        
    }
    private func checkLowBattery(percentage: Int, isPluggedIn: Bool) {
        if isPluggedIn {
            hasWarnedLowBattery = false
            return
        }
        if percentage <= lowBatteryThreshold && !hasWarnedLowBattery {
            hasWarnedLowBattery = true
            onLowBattery?(percentage)
        }
    }
    
    private func readBatteryHealth() {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return }
        defer { IOObjectRelease(service) }
        
        var props: Unmanaged<CFMutableDictionary>?
        guard IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS,
              let dict = props?.takeRetainedValue() as? [String: Any] else { return }
        
        if let cycles = dict["CycleCount"] as? Int {
            cycleCount = cycles
        }
        
        // Real health data lives inside "BatteryData"
        if let batteryData = dict["BatteryData"] as? [String: Any] {
            let nominal = batteryData["NominalChargeCapacity"] as? Int
            let design = batteryData["DesignCapacity"] as? Int
            
            if let nominal, let design, design > 0 {
                let raw = Double(nominal) / Double(design) * 100.0
                
                // Apple treats batteries in good condition as 100%
                // until degradation is significant enough to matter
                if cycleCount < 200 && condition == "Normal" && raw > 95 {
                    batteryHealth = 100
                } else {
                    batteryHealth = Int((raw / 5.0).rounded() * 5)
                }
            }
        }
        
        if let condition = dict["BatteryHealth"] as? String {
            self.condition = condition
        }
    }
}

