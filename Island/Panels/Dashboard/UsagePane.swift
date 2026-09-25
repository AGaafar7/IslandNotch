//
//  UsagePane.swift
//  Island
//
//  Created by Ahmed Gaafar on 16/10/2026.
//

import SwiftUI

struct UsagePane: View {
    @ObservedObject private var stats = UsageStats.shared
    
    var body: some View {
        HStack(spacing: 0) {
            StatColumn(
                title: "Peeks",
                value: format(stats.peekCount),
                subtitle: "notifications shown"
            )
            
            divider
            
            StatColumn(
                title: "Dashboard",
                value: format(stats.dashboardOpenCount),
                subtitle: "opens"
            )
            
            divider
            
            StatColumn(
                title: "Clipboard",
                value: format(stats.clipboardItemCount),
                subtitle: "items captured"
            )
            
            divider
            
            StatColumn(
                title: "Days Active",
                value: "\(stats.daysActive)",
                subtitle: "since first launch"
            )
        }
    }
    
    private var divider: some View {
        Divider()
            .background(Color.white.opacity(0.12))
            .padding(.vertical, 20)
    }
    
    private func format(_ number: Int) -> String {
        if number < 1000 {
            return "\(number)"
        } else if number < 1_000_000 {
            return String(format: "%.1fk", Double(number) / 1000)
        } else {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        }
    }
}

private struct StatColumn: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.8)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
