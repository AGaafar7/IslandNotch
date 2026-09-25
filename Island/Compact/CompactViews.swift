//
//  CompactViews.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import SwiftUI
import Combine

struct CompactLeadingView: View {
    @ObservedObject var state = CompactState.shared
       
    
    var body: some View {
            Group {
                switch state.current {
                case .battery:
                    BatteryLeading()
                        .onTapGesture {
                            Task { @MainActor in
                                NotchPeekManager.shared.showBatteryDetail()
                            }
                        }
                case .camera:
                    Image(systemName: "video.fill")
                        .foregroundStyle(.green)
                case .airPods:
                    Image(systemName: "airpods")
                        .foregroundStyle(.white)
                case .wifi:
                    Image(systemName: "wifi")
                        .foregroundStyle(.white)
                case .timer:
                    Image(systemName: "timer")
                        .foregroundStyle(.orange)
                case .microphone:
                    Image(systemName: "mic.fill")
                        .foregroundStyle(.red)
                
                }
            }
            .font(.system(size: 14, weight: .medium))
        }
}

struct CompactTrailingView: View {
    @ObservedObject var state = CompactState.shared
    
    var body: some View {
        Group {
            switch state.current {
            case .battery:
                BatteryTrailing()
            case .camera:
                EmptyView()
            case .airPods:
                EmptyView()
            case .wifi(let ssid):
                Text(ssid)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 90)
            case .timer(let endDate):
                TimerText(endDate: endDate)
            case .microphone:
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.red)
                    .tracking(0.5)
            }
        }
    }
}

struct BatteryLeading: View {
    @ObservedObject var power = PowerSourceMonitor.shared
    
    var body: some View {
        Image(systemName: batteryIconName)
            .foregroundStyle(batteryColor)
    }
    
    private var batteryIconName: String {
        if power.isPluggedIn { return "bolt.fill" }
        switch power.batteryPercentage {
        case 0..<20: return "battery.25"
        case 20..<50: return "battery.50"
        case 50..<80: return "battery.75"
        default: return "battery.100"
        }
    }
    
    private var batteryColor: Color {
        if power.isPluggedIn { return .green }
        switch power.batteryPercentage {
        case 0..<20: return .red
        case 20..<40: return .orange
        default: return .white
        }
    }
}

struct BatteryTrailing: View {
    @ObservedObject var power = PowerSourceMonitor.shared
    
    var body: some View {
        Text("\(power.batteryPercentage)%")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white)
            .monospacedDigit()
    }
}

struct TimerText: View {
    let endDate: Date
    
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(remaining)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.orange)
            .monospacedDigit()
            .onReceive(timer) { now = $0 }
    }
    
    private var remaining: String {
        let interval = max(0, endDate.timeIntervalSince(now))
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
