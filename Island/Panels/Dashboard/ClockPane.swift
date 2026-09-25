//
//  ClockPane.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import SwiftUI
import Combine

struct ClockPane: View {
    @State private var now = Date()
    
    // Top 5 cities in a line. Edit this list to change the panes.
    private let zones: [ClockZone] = [
        ClockZone(name: "Local",    identifier: TimeZone.current.identifier),
        ClockZone(name: "NYC",      identifier: "America/New_York"),
        ClockZone(name: "London",   identifier: "Europe/London"),
        ClockZone(name: "Dubai",    identifier: "Asia/Dubai"),
        ClockZone(name: "Tokyo",    identifier: "Asia/Tokyo"),
    ]
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(zones.enumerated()), id: \.offset) { index, zone in
                ClockColumn(zone: zone, now: now)
                    .frame(maxWidth: .infinity)
                
                if index < zones.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.12))
                        .padding(.vertical, 20)
                }
            }
        }
        .onReceive(timer) { now = $0 }
    }
}

// MARK: - Clock Column

private struct ClockColumn: View {
    let zone: ClockZone
    let now: Date
    
    var body: some View {
        VStack(spacing: 4) {
            Text(zone.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.8)
                .textCase(.uppercase)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(timeString)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                
                Text(amPm)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            if let dayOffset = dayOffset {
                Text(dayOffset)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
            } else {
                Text(" ") // keeps layout stable
                    .font(.system(size: 9))
            }
        }
        .padding(.vertical, 8)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: zone.identifier)
        formatter.dateFormat = "h:mm"
        return formatter.string(from: now)
    }
    
    private var amPm: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: zone.identifier)
        formatter.dateFormat = "a"
        return formatter.string(from: now)
    }
    
    /// Returns "Tomorrow", "Yesterday", or nil if same day as local
    private var dayOffset: String? {
        let calendar = Calendar.current
        let localDay = calendar.startOfDay(for: now)
        
        guard let zoneTimeZone = TimeZone(identifier: zone.identifier) else { return nil }
        var zoneCalendar = calendar
        zoneCalendar.timeZone = zoneTimeZone
        
        let zoneDay = zoneCalendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: localDay, to: zoneDay).day ?? 0
        
        switch days {
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default: return nil
        }
    }
}

// MARK: - Model

struct ClockZone {
    let name: String
    let identifier: String
}
