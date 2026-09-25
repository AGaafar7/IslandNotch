//
//  MicrophoneMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 10/10/2026.
//

import CoreAudio
import Foundation

final class MicrophoneMonitor {
    var onMicStateChange: ((Bool) -> Void)?
    
    private var currentDeviceID: AudioDeviceID = 0
    private var isRunning = false
    private var runningListenerBlock: AudioObjectPropertyListenerBlock?
    private let debouncer = Debouncer(delay: 0.3)
    
    func start() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main
        ) { [weak self] _, _ in
            self?.defaultInputChanged()
        }
        
        defaultInputChanged()
    }
    
    private func defaultInputChanged() {
        removeListenerForCurrentDevice()
        
        // 1. Get the new default input device
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let result = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        
        guard result == noErr, deviceID != 0 else { return }
        currentDeviceID = deviceID
        
        // 2. Register the listener for this device
        var runningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            self?.checkRunningState()
        }
        runningListenerBlock = block
        AudioObjectAddPropertyListenerBlock(deviceID, &runningAddress, DispatchQueue.main, block)
        
        // 3. Read the initial state
        checkRunningState()
    }
    
    private func removeListenerForCurrentDevice() {
        guard currentDeviceID != 0, let block = runningListenerBlock else { return }
        
        var runningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectRemovePropertyListenerBlock(
            currentDeviceID,
            &runningAddress,
            DispatchQueue.main,
            block
        )
        runningListenerBlock = nil
    }
    
    private func checkRunningState() {
        guard currentDeviceID != 0 else { return }
        
        var running: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let result = AudioObjectGetPropertyData(
            currentDeviceID,
            &address, 0, nil, &size, &running
        )
        
        guard result == noErr else { return }
        
        let newState = running != 0
        if newState != isRunning {
            isRunning = newState
            debouncer.call { [weak self] in
                self?.onMicStateChange?(newState)
            }
        }
    }
}
