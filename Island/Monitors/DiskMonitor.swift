//
//  DiskMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import Foundation
import Combine

@MainActor
final class DiskMonitor: ObservableObject {
    static let shared = DiskMonitor()
    
    @Published private(set) var freeBytes: Int64 = 0
    @Published private(set) var totalBytes: Int64 = 0
    
    var freeGB: Double { Double(freeBytes) / 1_073_741_824 }
    var totalGB: Double { Double(totalBytes) / 1_073_741_824 }
    var fractionUsed: Double {
        totalBytes > 0 ? 1.0 - (Double(freeBytes) / Double(totalBytes)) : 0
    }
    
    private init() {}
    
    func sample() {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ])
            
            if let free = values.volumeAvailableCapacityForImportantUsage {
                freeBytes = Int64(free)
            }
            if let total = values.volumeTotalCapacity {
                totalBytes = Int64(total)
            }
        } catch {
            // silently ignore
        }
    }
}
