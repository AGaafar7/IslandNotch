//
//  StatsPane.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import SwiftUI
import Combine

struct StatsPane: View {
    @ObservedObject private var cpu = CPUMonitor.shared
    @ObservedObject private var memory = MemoryMonitor.shared
    @ObservedObject private var disk = DiskMonitor.shared
    @ObservedObject private var network = NetworkMonitor.shared
    
    @State private var thermalState: ProcessInfo.ThermalState = .nominal
    
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            StatColumn(
                title: "CPU",
                value: "\(Int(cpu.usage * 100))%",
                subtitle: coreSubtitle,
                accent: cpuAccent
            )
            
            divider
            
            StatColumn(
                title: "Memory",
                value: String(format: "%.1f GB", memory.usedGB),
                subtitle: String(format: "%d%% of %.0f GB",
                                 Int(memory.fractionUsed * 100),
                                 memory.totalGB),
                accent: memoryAccent
            )
            
            divider
            
            StatColumn(
                title: "Disk",
                value: String(format: "%.0f GB", disk.freeGB),
                subtitle: "free of \(Int(disk.totalGB)) GB",
                accent: diskAccent
            )
            
            divider
            
            StatColumn(
                title: "Network",
                value: "↓ \(network.formattedDownload())",
                subtitle: "↑ \(network.formattedUpload())",
                accent: .white
            )
            
            divider
            
            StatColumn(
                title: "Thermal",
                value: thermalLabel,
                subtitle: "processor state",
                accent: thermalAccent
            )
        }
        .onReceive(timer) { _ in
            cpu.sample()
            memory.sample()
            disk.sample()
            network.sample()
            thermalState = ProcessInfo.processInfo.thermalState
        }
        .onAppear {
            cpu.sample()
            memory.sample()
            disk.sample()
            network.sample()
            thermalState = ProcessInfo.processInfo.thermalState
        }
    }
    
    private var divider: some View {
        Divider()
            .background(Color.white.opacity(0.12))
            .padding(.vertical, 20)
    }
    
    private var coreSubtitle: String {
        "\(ProcessInfo.processInfo.processorCount) cores"
    }
    
    private var cpuAccent: Color {
        switch cpu.usage {
        case 0..<0.5: return .white
        case 0.5..<0.8: return .orange
        default: return .red
        }
    }
    
    private var memoryAccent: Color {
        switch memory.fractionUsed {
        case 0..<0.7: return .white
        case 0.7..<0.9: return .orange
        default: return .red
        }
    }
    
    private var diskAccent: Color {
        switch disk.fractionUsed {
        case 0..<0.85: return .white
        case 0.85..<0.95: return .orange
        default: return .red
        }
    }
    
    private var thermalLabel: String {
        switch thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
    
    private var thermalAccent: Color {
        switch thermalState {
        case .nominal: return .white
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .white
        }
    }
}

// MARK: - Stat Column

private struct StatColumn: View {
    let title: String
    let value: String
    let subtitle: String
    let accent: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(0.8)
                .textCase(.uppercase)
            
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(accent)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(subtitle)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
