//
//  UsageStats.swift
//  Island
//
//  Created by Ahmed Gaafar on 16/10/2026.
//

import Foundation
import Combine

@MainActor
final class UsageStats: ObservableObject {
    static let shared = UsageStats()
    
    @Published private(set) var peekCount: Int = 0
    @Published private(set) var dashboardOpenCount: Int = 0
    @Published private(set) var clipboardItemCount: Int = 0
    @Published private(set) var firstLaunchDate: Date = Date()
    
    var daysActive: Int {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: firstLaunchDate)
        let to = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0
        return days + 1
    }
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let peekCount = "usage.peekCount"
        static let dashboardOpenCount = "usage.dashboardOpenCount"
        static let clipboardItemCount = "usage.clipboardItemCount"
        static let firstLaunchDate = "usage.firstLaunchDate"
    }
    
    private init() {
        load()
    }
    
    // MARK: - Increments
    
    func incrementPeeks() {
        peekCount += 1
        defaults.set(peekCount, forKey: Keys.peekCount)
    }
    
    func incrementDashboard() {
        dashboardOpenCount += 1
        defaults.set(dashboardOpenCount, forKey: Keys.dashboardOpenCount)
    }
    
    func incrementClipboard() {
        clipboardItemCount += 1
        defaults.set(clipboardItemCount, forKey: Keys.clipboardItemCount)
    }
    
    // MARK: - Reset
    
    func reset() {
        peekCount = 0
        dashboardOpenCount = 0
        clipboardItemCount = 0
        firstLaunchDate = Date()
        
        defaults.set(0, forKey: Keys.peekCount)
        defaults.set(0, forKey: Keys.dashboardOpenCount)
        defaults.set(0, forKey: Keys.clipboardItemCount)
        defaults.set(firstLaunchDate, forKey: Keys.firstLaunchDate)
    }
    
    // MARK: - Persistence
    
    private func load() {
        peekCount = defaults.integer(forKey: Keys.peekCount)
        dashboardOpenCount = defaults.integer(forKey: Keys.dashboardOpenCount)
        clipboardItemCount = defaults.integer(forKey: Keys.clipboardItemCount)
        
        if let stored = defaults.object(forKey: Keys.firstLaunchDate) as? Date {
            firstLaunchDate = stored
        } else {
            firstLaunchDate = Date()
            defaults.set(firstLaunchDate, forKey: Keys.firstLaunchDate)
        }
    }
}
