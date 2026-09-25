//
//  Debouncer.swift
//  Island
//
//  Created by Ahmed Gaafar on 25/09/2026.
//

import Foundation

final class Debouncer {
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    private let delay: TimeInterval
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.queue = queue
        self.delay = delay
    }
    
    func call(_ action: @escaping () -> Void) {
        workItem?.cancel()
        
        let item = DispatchWorkItem(block: action)
        workItem = item
        queue.asyncAfter(deadline: .now() + delay, execute: item)
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}
