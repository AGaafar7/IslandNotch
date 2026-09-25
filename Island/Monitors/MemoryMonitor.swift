//
//  MemoryMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import Foundation
import Darwin
import Combine

@MainActor
final class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()
    
    @Published private(set) var usedBytes: UInt64 = 0
    @Published private(set) var totalBytes: UInt64 = 0
    
    var usedGB: Double { Double(usedBytes) / 1_073_741_824 }
    var totalGB: Double { Double(totalBytes) / 1_073_741_824 }
    var fractionUsed: Double {
        totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0
    }
    
    private init() {}
    
    func sample() {
        totalBytes = ProcessInfo.processInfo.physicalMemory
        
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )
        
        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { reboundPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, reboundPtr, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return }
        
        let pageSize = UInt64(vm_kernel_page_size)
        
        // "Used" = active + wired + compressed (approximates Activity Monitor)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        
        usedBytes = active + wired + compressed
    }
}
