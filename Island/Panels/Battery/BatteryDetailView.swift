//
//  BatteryDetailView.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI

struct BatteryDetailView: View {
    @ObservedObject var power = PowerSourceMonitor.shared
    var onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(power.batteryPercentage)%")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                
                if power.isCharging {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.green)
                        .font(.title2)
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            VStack(spacing: 8) {
                detailRow("Status", value: statusText)
                detailRow("Time", value: timeText)
                detailRow("Health", value: "\(power.batteryHealth)%")
                detailRow("Cycles", value: "\(power.cycleCount)")
                detailRow("Condition", value: power.condition)
            }
        }
        .padding(20)
        .frame(width: 320, height: 220)
    }
    
    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
    }
    
    private var statusText: String {
        if power.isCharging { return "Charging" }
        if power.isPluggedIn { return "Plugged in, not charging" }
        return "On battery"
    }
    
    private var timeText: String {
        guard power.timeRemaining > 0 else { return "Calculating…" }
        let hours = power.timeRemaining / 60
        let minutes = power.timeRemaining % 60
        return power.isCharging
            ? "\(hours)h \(minutes)m to full"
            : "\(hours)h \(minutes)m remaining"
    }
}
