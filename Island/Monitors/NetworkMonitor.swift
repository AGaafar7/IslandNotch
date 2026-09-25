//
//  NetworkMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 15/10/2026.
//

import Foundation
import Darwin
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var downloadBytesPerSec: Double = 0
    @Published private(set) var uploadBytesPerSec: Double = 0
    
    private var previousReceived: UInt64 = 0
    private var previousSent: UInt64 = 0
    private var previousSampleDate: Date?
    
    private init() {}
    
    func sample() {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let first = addresses else { return }
        defer { freeifaddrs(addresses) }
        
        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0
        
        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            
            let flags = Int32(current.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            
            guard isUp, !isLoopback else { continue }
            guard let addr = current.pointee.ifa_addr else { continue }
            guard addr.pointee.sa_family == UInt8(AF_LINK) else { continue }
            
            guard let dataPtr = current.pointee.ifa_data else { continue }
            let data = dataPtr.assumingMemoryBound(to: if_data.self).pointee
            
            totalReceived += UInt64(data.ifi_ibytes)
            totalSent += UInt64(data.ifi_obytes)
        }
        
        let now = Date()
        if let previousDate = previousSampleDate {
            let elapsed = now.timeIntervalSince(previousDate)
            if elapsed > 0 {
                let rx = UInt64(max(0, Int64(totalReceived) - Int64(previousReceived)))
                let tx = UInt64(max(0, Int64(totalSent) - Int64(previousSent)))
                downloadBytesPerSec = Double(rx) / elapsed
                uploadBytesPerSec = Double(tx) / elapsed
            }
        }
        
        previousReceived = totalReceived
        previousSent = totalSent
        previousSampleDate = now
    }
    
    func formattedDownload() -> String {
        format(downloadBytesPerSec)
    }
    
    func formattedUpload() -> String {
        format(uploadBytesPerSec)
    }
    
    private func format(_ bytesPerSec: Double) -> String {
        if bytesPerSec < 1024 {
            return "\(Int(bytesPerSec)) B/s"
        } else if bytesPerSec < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024)
        } else {
            return String(format: "%.1f MB/s", bytesPerSec / 1_048_576)
        }
    }
}
