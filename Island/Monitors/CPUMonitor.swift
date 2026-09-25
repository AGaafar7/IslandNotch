//
//  CPUMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import Foundation
import Darwin
import Combine

@MainActor
final class CPUMonitor: ObservableObject {
    static let shared = CPUMonitor()
    
    @Published private(set) var usage: Double = 0  // 0.0 to 1.0
    
    private var previousInfo: processor_info_array_t?
    private var previousCount: mach_msg_type_number_t = 0
    
    private init() {}
    
    func sample() {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        
        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &cpuCount,
            &info,
            &infoCount
        )
        
        guard result == KERN_SUCCESS, let info else { return }
        
        defer {
            // Free the old sample
            if let previousInfo {
                vm_deallocate(
                    mach_task_self_,
                    vm_address_t(bitPattern: previousInfo),
                    vm_size_t(previousCount) * vm_size_t(MemoryLayout<integer_t>.size)
                )
            }
            previousInfo = info
            previousCount = infoCount
        }
        
        guard let previous = previousInfo else {
            // First sample — no delta to compute
            return
        }
        
        var totalUsage: Double = 0
        var totalTicks: Double = 0
        
        let cpuCountInt = Int(cpuCount)
        let stateCount = Int(CPU_STATE_MAX)
        
        for cpu in 0..<cpuCountInt {
            let offset = cpu * stateCount
            
            let user = Double(info[offset + Int(CPU_STATE_USER)] - previous[offset + Int(CPU_STATE_USER)])
            let system = Double(info[offset + Int(CPU_STATE_SYSTEM)] - previous[offset + Int(CPU_STATE_SYSTEM)])
            let nice = Double(info[offset + Int(CPU_STATE_NICE)] - previous[offset + Int(CPU_STATE_NICE)])
            let idle = Double(info[offset + Int(CPU_STATE_IDLE)] - previous[offset + Int(CPU_STATE_IDLE)])
            
            let busy = user + system + nice
            let total = busy + idle
            
            totalUsage += busy
            totalTicks += total
        }
        
        guard totalTicks > 0 else { return }
        usage = totalUsage / totalTicks
    }
}
