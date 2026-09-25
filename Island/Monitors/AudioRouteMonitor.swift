//
//  AudioRouteMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import CoreAudio
import Foundation

enum AudioRouteEvent {
    case airPodsConnected(name: String)
    case airPodsDisconnected(name: String)
    case otherDeviceChanged(name: String)
}

final class AudioRouteMonitor {
    var onRouteEvent: ((AudioRouteEvent) -> Void)?
    
    private var previousDeviceName: String?
    private let debouncer = Debouncer(delay: 0.8)
    
    func start() {
        checkDefaultDevice()
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main
        ) { [weak self] _, _ in
            self?.checkDefaultDevice()
        }
    }
    
    private func checkDefaultDevice() {
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        
        guard result == noErr, deviceID != 0 else { return }
        
        var name: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        
        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let nameResult = AudioObjectGetPropertyData(
            deviceID, &nameAddress, 0, nil, &nameSize, &name
        )
        
        guard nameResult == noErr else { return }
        
        let deviceName = name?.takeUnretainedValue() as String? ?? "Unknown"
        guard deviceName != previousDeviceName else { return }
        
        let oldName = previousDeviceName
        previousDeviceName = deviceName
        
        let event = classifyTransition(from: oldName, to: deviceName)
        guard let event else { return }
        
        debouncer.call { [weak self] in
            self?.onRouteEvent?(event)
        }
    }
    
    private func classifyTransition(from oldName: String?, to newName: String) -> AudioRouteEvent? {
        let wasAirPods = oldName?.lowercased().contains("airpods") ?? false
        let isAirPods = newName.lowercased().contains("airpods")
        
        if isAirPods && !wasAirPods {
            return .airPodsConnected(name: newName)
        } else if !isAirPods && wasAirPods {
            return .airPodsDisconnected(name: oldName ?? "AirPods")
        } else {
            return .otherDeviceChanged(name: newName)
        }
    }
}
