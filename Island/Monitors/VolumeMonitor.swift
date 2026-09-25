//
//  VolumeMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import AppKit
import CoreAudio
import AudioToolbox

final class VolumeMonitor {
    var onVolumeChange: ((Float) -> Void)?
    
    private var monitor: Any?
    private var lastVolume: Float = -1
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined) { [weak self] event in
            self?.handleSystemEvent(event)
        }
    }
    
    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func handleSystemEvent(_ event: NSEvent) {
        // subtype 8 = NX_SUBTYPE_AUX_CONTROL_BUTTONS
        guard event.subtype.rawValue == 8 else { return }
        
        let keyCode = (event.data1 & 0xFFFF0000) >> 16
        let keyFlags = (event.data1 & 0x0000FFFF)
        let isKeyDown = ((keyFlags & 0xFF00) >> 8) == 0xA
        
        guard isKeyDown else { return }
        
        // Volume keys
        // 0 = NX_KEYTYPE_SOUND_UP
        // 1 = NX_KEYTYPE_SOUND_DOWN
        // 7 = NX_KEYTYPE_MUTE
        guard keyCode == 0 || keyCode == 1 || keyCode == 7 else { return }
        
        // Give macOS a moment to apply the volume change, then read
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.readCurrentVolume()
        }
    }
    
    private func readCurrentVolume() {
        // Get the default output device
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
        
        // Read the volume
        var volume: Float32 = 0
        var volumeSize = UInt32(MemoryLayout<Float32>.size)
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let volResult = AudioObjectGetPropertyData(
            deviceID,
            &volumeAddress, 0, nil, &volumeSize, &volume
        )
        
        guard volResult == noErr else { return }
        
        // Only fire if it actually changed
        if abs(volume - lastVolume) < 0.001 { return }
        lastVolume = volume
        
        onVolumeChange?(volume)
    }
}
