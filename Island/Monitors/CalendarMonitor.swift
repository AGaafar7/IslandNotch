//
//  CalenderMonitor.swift
//  Island
//
//  Created by Ahmed Gaafar on 09/10/2026.
//

import Foundation
import EventKit
import Combine

@MainActor
final class CalendarMonitor: ObservableObject {
    static let shared = CalendarMonitor()
    
    var onUpcomingEvent: ((UpcomingEvent) -> Void)?
    
    private let eventStore = EKEventStore()
    private var timer: Timer?
    private var notifiedEventIDs: Set<String> = []
    private let notifyMinutesBefore = 5
    
    private init() {}
    
    func start() {
        requestAccess { [weak self] granted in
            guard granted else {
                print("[CalenderMonitor] Access denied")
                return
            }
            self?.startPolling()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Permission
    private func requestAccess(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if let error {
                    print("[CalendarMonitor] Access error: \(error)")
                }
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error {
                        print("[CalendarMonitor] Access error: \(error)")
                    }
                    DispatchQueue.main.async { completion(granted) }
                }
        }
    }
    
    private func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.checkUpcomingEvents()
            }
        }
        checkUpcomingEvents()
    }
    
    private func checkUpcomingEvents() {
        let now = Date()
        let windowEnd = now.addingTimeInterval(TimeInterval(notifyMinutesBefore * 60 + 30))
        let predicate = eventStore.predicateForEvents(withStart: now, end: windowEnd, calendars: nil)
        
        let events = eventStore.events(matching: predicate)
        
        for event in events {
            guard let eventID = event.eventIdentifier else { continue }
                        guard !notifiedEventIDs.contains(eventID) else { continue }
                        guard let startDate = event.startDate else { continue }
                        
                        let secondsUntil = startDate.timeIntervalSince(now)
                        let minutesUntil = Int(secondsUntil / 60)
                        
                        guard minutesUntil >= 0 && minutesUntil <= notifyMinutesBefore else { continue }
                        
                        notifiedEventIDs.insert(eventID)
            let upcoming = UpcomingEvent(
                            title: event.title ?? "Event",
                            startDate: startDate,
                            minutesUntil: minutesUntil
                        )
            onUpcomingEvent?(upcoming)
        }
        let oldIDs = notifiedEventIDs.filter { id in
                   guard let event = eventStore.event(withIdentifier: id) else { return true }
                   guard let end = event.endDate else { return true }
                   return end < now
               }
        oldIDs.forEach { notifiedEventIDs.remove($0) }
    }
}

struct UpcomingEvent {
    let title: String
    let startDate: Date
    let minutesUntil: Int
}
