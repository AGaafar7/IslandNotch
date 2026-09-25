//
//  CompactState.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI
import Combine

@MainActor
final class CompactState: ObservableObject {
    static let shared = CompactState()
    
    enum Content: Equatable {
        case battery
        case camera
        case airPods
        case wifi(String)
        case timer(endDate: Date)
        case microphone
    }
    
    private var isMicActive = false
    
    func setMicActive(_ active: Bool) {
        isMicActive = active
        update()
    }
    
    @Published var current: Content = .battery
    
    var onTimerFinished: (() -> Void)?
    
    private var isCameraOpen = false
    private var airPodsConnected = false
    private var currentSSID: String?
    private var defaultSSID: String?
    private var timerEnd: Date?
    private var timerDuration: TimeInterval = 0
    private var timerTick: Timer?
    
    private init() {}
    
    // MARK: - Setters
    
    func setCameraOpen(_ open: Bool) {
        isCameraOpen = open
        update()
    }
    
    func setAirPods(connected: Bool) {
        airPodsConnected = connected
        update()
    }
    
    func setSSID(_ ssid: String?) {
        if defaultSSID == nil { defaultSSID = ssid }
        currentSSID = ssid
        update()
    }
    
    // MARK: - Timer
    
    var isTimerRunning: Bool {
        if let end = timerEnd, end > Date() { return true }
        return false
    }
    
    func startTimer(seconds: TimeInterval) {
        print("[Timer] Starting: \(seconds)s")
        timerDuration = seconds
        timerEnd = Date().addingTimeInterval(seconds)
        update()
        scheduleCompletionCheck()
    }
    
    func cancelTimer() {
        timerEnd = nil
        timerDuration = 0
        timerTick?.invalidate()
        timerTick = nil
        update()
    }
    
    private func scheduleCompletionCheck() {
        timerTick?.invalidate()
        timerTick = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let end = self.timerEnd else { return }
                if end <= Date() {
                    self.timerTick?.invalidate()
                    self.timerTick = nil
                    self.timerEnd = nil
                    self.timerDuration = 0
                    self.update()
                    self.onTimerFinished?()
                }
            }
        }
    }
    
    private func update() {
        if isCameraOpen {
            current = .camera
        } else if isMicActive {
            current = .microphone
        } else if let end = timerEnd, end > Date() {
            current = .timer(endDate: end)
        } else if airPodsConnected {
            current = .airPods
        } else if let ssid = currentSSID, ssid != defaultSSID {
            current = .wifi(ssid)
        } else {
            current = .battery
        }
    }
}
